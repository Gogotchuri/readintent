import os
from dataclasses import dataclass


@dataclass
class Config:
    """Config class with default options, overriden by the ENV"""
	redis_url: str = "redis://localhost:6379/0"
	stream_input_event: str = "scrape:jobs"
	stream_output_event: str = "scrape:results"
	consumer_group: str = "scraper-group"
	consumer_name: str = "scraper-1"
	block_ms: int = 5000
	max_workers: int = 4
	browser_max_tabs: int = 4
	browser_restart_after: int = 500
	browser_timeout: float = 30.0


def load_config() -> Config:
	return Config(
		redis_url=os.environ.get("SCRAPER_REDIS_URL", Config.redis_url),
		stream_input_event=os.environ.get("SCRAPER_STREAM_INPUT", Config.stream_input_event),
		stream_output_event=os.environ.get("SCRAPER_STREAM_OUTPUT", Config.stream_output_event),
		consumer_group=os.environ.get("SCRAPER_CONSUMER_GROUP", Config.consumer_group),
		consumer_name=os.environ.get("SCRAPER_CONSUMER_NAME", Config.consumer_name),
		block_ms=int(os.environ.get("SCRAPER_BLOCK_MS", str(Config.block_ms))),
		max_workers=int(os.environ.get("SCRAPER_MAX_WORKERS", str(Config.max_workers))),
		browser_max_tabs=int(os.environ.get("SCRAPER_BROWSER_MAX_TABS", str(Config.browser_max_tabs))),
		browser_restart_after=int(os.environ.get("SCRAPER_BROWSER_RESTART_AFTER", str(Config.browser_restart_after))),
		browser_timeout=float(os.environ.get("SCRAPER_BROWSER_TIMEOUT", str(Config.browser_timeout))),
	)
