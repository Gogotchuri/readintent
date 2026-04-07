import logging

import redis

from config import load_config
from event_consumer import EventHub
from tts.pipeline import PhonemizerPipeline


def main():
    logging.basicConfig(level=logging.INFO)
    config = load_config()
    phonemizer = PhonemizerPipeline()
    redis_client = redis.Redis.from_url(config.redis_url, protocol=3, decode_responses=True)
    hub = EventHub(config, redis_client, phonemizer)
    hub.consume_events()

if __name__ == "__main__":
    main()
