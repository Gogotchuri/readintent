import logging

import redis
from kokoro import KPipeline

from config import load_config
from event_consumer import EventHub
from tts.pipeline import PhonemizerPipeline


def main():
    logging.basicConfig(level=logging.INFO)
    config = load_config()
    # Initialize PhonemizerPipeline Service
    phonemizer = PhonemizerPipeline(KPipeline(lang_code='a', model=False))
    # Initialize the redis client and setup EventHub to pass event through PhonemizerPipeline service as they come
    redis_client = redis.Redis.from_url(config.redis_url, protocol=3, decode_responses=True)
    hub = EventHub(config, redis_client, phonemizer)
    hub.consume_events()

if __name__ == "__main__":
    main()
