import os
from dataclasses import dataclass


@dataclass
class Config:
	redis_url: str = "redis://localhost:6379/0"
	stream_input_event: str = "scrape:results"
	stream_output_event: str = "phonemize:results"
	consumer_group: str = "phonemizer-group"
	consumer_name: str = "phonemizer-1"
	block_ms: int = 5000


def load_config() -> Config:
	return Config(
		redis_url=os.environ.get("REDIS_URL", Config.redis_url),
		stream_input_event=os.environ.get("STREAM_INPUT", Config.stream_input_event),
		stream_output_event=os.environ.get("STREAM_OUTPUT", Config.stream_output_event),
		consumer_group=os.environ.get("CONSUMER_GROUP", Config.consumer_group),
		consumer_name=os.environ.get("CONSUMER_NAME", Config.consumer_name),
		block_ms=int(os.environ.get("BLOCK_MS", str(Config.block_ms))),
	)
