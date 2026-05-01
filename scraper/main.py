import logging

import redis

from article_extraction import ArticleExtractor
from config import load_config
from event_consumer import EventHub


def main():
    logging.basicConfig(level=logging.INFO)
    # Loads config from ENV file and if the variables not available sets default
    config = load_config()
    # Initializes ArticleExtractor Service
    extractor = ArticleExtractor()
    # Initialize the redis client and setup EventHub to pass event through ArticleExtractor service as they come
    redis_client = redis.Redis.from_url(config.redis_url, protocol=3, decode_responses=True)
    hub = EventHub(config,redis_client, extractor)
    hub.consume_events()

if __name__ == "__main__":
    main()
