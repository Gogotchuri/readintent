import json
import logging
from typing import List, Tuple, cast

import redis

from config import Config
from tts.pipeline import PhonemizerPipeline

logger = logging.getLogger(__name__)


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
            print("Waiting for events...")
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
                print("No events received")
                return

            # We will only need the specific event stream
            # AFAIK, this should never return the other entries given the way we call xreadgroup
            event_list = batched_events.get(self.config.stream_input_event, [])
            if not event_list:
                print("No events received for stream")
                return

            # The event list is a list of list of tuples. The outer list is redundant given our call structure
            # We should only have a single batch per stream
            for event_id, event_data in event_list[0]:
                self.process_event(event_id, event_data)

        except Exception as e:
            logger.error(f"Error consuming events: {e}")

    def process_event(self, event_id: str, event_data: dict):
        """Process a single event from the Redis stream"""
        try:
            result_data = json.loads(event_data.get("result", '{}'))
            pure_text = result_data["pure_text"]
            if not pure_text:
                logger.error(f"The event doesn't contain the pure_text and can't be phonemized {event_id}")
                raise ValueError("expected pure_text to be part of the result")
            result = self.phonemizer_pipeline.generate_phonemes(pure_text)
            self.redis_client.xadd(
                self.config.stream_output_event,
                {"result": json.dumps([r.to_dict() for r in result])},
            )
            logger.info(
                f"Published phonemizer result for event {event_id} to stream '{self.config.stream_output_event}'"
            )
        except Exception as e:
            logger.error(f"Error parsing event data for event {event_id}: {e}")
            try:
                self.redis_client.xadd(
                    self.config.stream_output_event,
                    {"error": json.dumps({"event_id": event_id, "error": str(e)})},
                )
                logger.info(
                    f"Published error for event {event_id} to stream '{self.config.stream_output_event}'"
                )
            except Exception as publish_error:
                logger.error(
                    f"Error publishing error for event {event_id}: {publish_error}"
                )
            return

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
        # Ensure the stream exists
        self.ensure_group()

        # Start consuming events
        while True:
            self._consume_single_event_batch()
