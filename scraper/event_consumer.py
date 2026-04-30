import json
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import List, Tuple, cast

import redis

from article_extraction import ArticleExtractor, ExtractorError
from config import Config

logger = logging.getLogger(__name__)

class EventHub:
	def __init__(
			self,
			conf: Config,
			redis_client: redis.Redis,
			article_extractor: ArticleExtractor,
	) -> None:
		self.config = conf
		self.redis_client = redis_client
		self.article_extractor = article_extractor

	def _consume_single_event_batch(self, executor: ThreadPoolExecutor) -> None:
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
				executor.submit(self.process_event, event_id, event_data)

		except Exception as e:
			logger.error(f"Error consuming events: {e}")

	def process_event(self, event_id: str, event_data: dict):
		"""Process a single event from the Redis stream"""
		url = event_data["url"]
		if not url:
			logger.error(f"Error processing event ({event_id}) {event_data}")
			# In this case there has been a some kind of issue upstream and we should ditch the event, hence acknowledge it here
			self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
			return

		try:
			# Parse the event data
			article = self.article_extractor.extract(url)
			if isinstance(article, ExtractorError):
				raise article
			# Publish the result to the output stream
			self.redis_client.xadd(
				self.config.stream_output_event,
				{"result": json.dumps(article.__dict__)},
			)
			logger.info(
				f"Published result for event {event_id} to stream '{self.config.stream_output_event}'"
			)
			self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
		except Exception as e:
			url = event_data["url"]
			logger.error(f"Error processing event ({url}) {event_id}: {e}")
			try:
				# Add error to the stream for the URL
				self.redis_client.xadd(
					self.config.stream_output_event,
					{"error": json.dumps({"url": url, "msg": str(e)})},
				)
				logger.info(
					f"Published error for event {event_id} to stream '{self.config.stream_output_event}'"
				)
				self.redis_client.xack(self.config.stream_input_event, self.config.consumer_group, event_id)
			except Exception as publish_error:
				logger.error(
					f"Error publishing error for event {event_id}: {publish_error}"
				)

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
		with ThreadPoolExecutor(max_workers=self.config.max_workers) as executor:
			while True:
				self._consume_single_event_batch(executor)
