import json
import logging
import time
import threading
from typing import List, Tuple, cast

import redis

from config import Config
from tts.pipeline import PhonemizerPipeline

logger = logging.getLogger(__name__)


## Here are the main rules for EventHub:
# - The input event must have a non-empty article_id and pure_text, otherwise we remove the event early from processing and return error
# - On processing failure, the event is left pending for retry by the background sweep
# - The retry sweep uses XAUTOCLAIM to reclaim idle pending messages and retries them up to max_retries
# - The primary identification of the event will always be article_id, the subscriber can ignore event not including the field
class EventHub:
    def __init__(
            self,
            conf: Config,
            redis_client: redis.Redis,
            phonemizer_pipeline: PhonemizerPipeline,
    ) -> None:
        self.config = conf
        self.redis_client = redis_client
        self.phonemizer_pipeline = phonemizer_pipeline

    def _consume_single_event_batch(self) -> None:
        """Consume a single batch of events from the Redis stream and process them"""
        try:
            logger.debug("Waiting for events...")
            batched_events = cast(
                dict[str, List[List[Tuple[str, dict]]]],
                self.redis_client.xreadgroup(
                    groupname=self.config.consumer_group,
                    consumername=self.config.consumer_name,
                    streams={self.config.stream_input_event: ">"},
                    count=10,
                    block=self.config.block_ms,
                ),
            )

            if not batched_events:
                logger.debug("No events received")
                return

            # We will only need the specific event stream
            # AFAIK, this should never return the other entries given the way we call xreadgroup
            event_list = batched_events.get(self.config.stream_input_event, [])
            if not event_list:
                logger.debug("No events received for stream")
                return

            # The event list is a list of list of tuples. The outer list is redundant given our call structure
            # We should only have a single batch per stream
            for event_id, event_data in event_list[0]:
                self.process_event(event_id, event_data)

        except Exception as e:
            logger.error(f"Error consuming events: {e}")

    def process_event(self, event_id: str, event_data: dict):
        """Process a single event from the Redis stream"""
        article_id = event_data.get("article_id", "")

        # if the article_id is missing we can't correlate downstream, just ack(discard)
        if not article_id:
            logger.error(f"Event {event_id} missing article_id, discarding: {event_data}")
            self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
            return

        # Parse result JSON and check for pure_text, without it the event is invalid and we can produce phonemes for it
        try:
            result_data = json.loads(event_data.get("result", '{}'))
            pure_text = result_data.get("pure_text", "")
        except (json.JSONDecodeError, AttributeError):
            pure_text = ""

        if not pure_text:
            logger.error(f"Event {event_id} missing pure_text for article {article_id}")
            self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
            self.redis_client.xadd(
                self.config.stream_output_event,
                {"article_id": article_id, "error": json.dumps({"msg": "missing pure_text"})},
            )
            return

        try:
            result = self.phonemizer_pipeline.generate_phonemes(pure_text)
            # SUCCESS, publish result downstream and ack the event
            self.redis_client.xadd(
                self.config.stream_output_event,
                {"article_id": article_id, "result": json.dumps([r.to_dict() for r in result])},
            )
            self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
            logger.info(
                f"Published phonemizer result for event {event_id} to stream '{self.config.stream_output_event}'"
            )
        except Exception as e:
            # This exception is no-op the pending loop will take care of this event in a minute
            logger.error(f"Error processing event {event_id}: {e}")

    def _retry_pending_events(self):
        """Claim idle pending messages and retry or give up based on times_delivered."""
        result = self.redis_client.xautoclaim(
            name=self.config.stream_input_event,
            groupname=self.config.consumer_group,
            consumername=self.config.consumer_name,
            min_idle_time=self.config.min_idle_time,
            start_id="0-0",
        )
        if not result or not result[1]:
            return

        claimed_ids = [msg_id for msg_id, _ in result[1]]
        pending_info = self.redis_client.xpending_range(
            name=self.config.stream_input_event,
            groupname=self.config.consumer_group,
            min=claimed_ids[0], max=claimed_ids[-1], count=len(claimed_ids),
        )
        delivery_counts = {p["message_id"]: p["times_delivered"] for p in pending_info}

        for msg_id, msg_data in result[1]:
            if delivery_counts.get(msg_id, 0) >= self.config.max_retries:
                # Give up — publish error downstream, ack
                article_id = msg_data.get("article_id", "")
                if article_id:
                    self.redis_client.xadd(
                        self.config.stream_output_event,
                        {"article_id": article_id, "error": json.dumps({"msg": "max retries exceeded"})},
                    )
                self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, msg_id)
                logger.warning(f"Gave up on event {msg_id} after max retries")
                continue

            # Under max retries — process again
            self.process_event(msg_id, msg_data)

    def _retry_loop(self):
        """Background loop: every 60s, claim and retry idle pending messages."""
        while True:
            try:
                self._retry_pending_events()
            except Exception as e:
                logger.error(f"Error in retry sweep: {e}")
            time.sleep(60)

    def ensure_group(self):
        # Ensure the stream exists
        try:
            self.redis_client.xgroup_create(
                name=self.config.stream_input_event,
                groupname=self.config.consumer_group,
                id="0",
                mkstream=True,
            )
        except Exception as e:
            if "BUSYGROUP" in str(e):
                logger.info(
                    f"Consumer group '{self.config.consumer_group}' already exists for stream '{self.config.stream_input_event}'"
                )
            else:
                logger.error(f"Error creating consumer group: {e}")
                raise e

    def consume_events(self):
        """Continuously consume events from the Redis stream and process them"""
        self.ensure_group()
        logger.info("event consumer started")

        # Start retry sweep as a concurrent background thread
        retry_thread = threading.Thread(target=self._retry_loop, daemon=True)
        retry_thread.start()

        # Start consuming events
        while True:
            self._consume_single_event_batch()
