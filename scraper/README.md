# Scraper for Read Intent

This directory includes self-contained Python service for scraping articles.

## Project Setup
This project uses tools from [astral.sh](https://docs.astral.sh/). Specifically `uv` for package management and `ty` for typechecking (Yes, this project uses type-checked Python).

### Configuration
Configuration is read and built in [`./config.py`](./config.py) from ENV variables and defaults.

Here are all of the ENV variables that can be set for this project:
- "SCRAPER_REDIS_URL" - Redis connection string
- "SCRAPER_STREAM_INPUT" - Redis Streams, input event name
- "SCRAPER_STREAM_OUTPUT" - Redis Streams, output event name
- "SCRAPER_CONSUMER_GROUP" - Redis Streams, consumer group
- "SCRAPER_CONSUMER_NAME" - Redis Streams, consumer name
- "SCRAPER_BLOCK_MS" - Redis Streams, time to block on events
- "SCRAPER_MIN_IDLE_TIME" - Redis Streams, min idle time for XAUTOCLAIM for failed requests
- "SCRAPER_MAX_WORKERS" - Parallel workers for scraping (We will still lock per-origin to not spam the origin)
- "SCRAPER_MAX_RETRIES" - Max retries after failure (We will not retry if the input is malformed)

*To run this serice the Redis server should already be running*
### Run with Docker
From this directory build and run the Docker image with `docker build -t readintent_scraper . && docker run readintent_scraper`

### Run with `uv` (without Docker)
Install dependencies with `uv sync --locked` and run the main.py with `uv run main.py`

## I/O event structure
The input events must contain non-empty valid `article_id` (unique article integer identifier) and `url` the URL of the article. The event can also include `html` property, indicating that we pre-extracted the complete rendered DOM and can use that instead of downloading it again from the URL. Although in case the extraction from the provided `html` fails, we will fallback to downloading the article again from the URL.

The output events will always contain `article_id` and in case of *success* `result` with JSON marshalled [**ExtractedArticle**](./article_extractor.py) object. In case of *error*, the event will contain `error` property with `msg` property inside of it.

## Project Structure
- `main.py` - The main entry point. Sets up logging, redis client and starts consuming events.
- `config.py` - Build config from ENV and assign from default values when missing.
- `event_consumer.py` - Runs continuos loops concurrently (number of threads configured with MAX_WORKERS variable). Each loop consumes events from the configured Redis stream, group name, and consumer name. Runs the retry loop in a different thread with MAX_RETRIES and MIN_IDLE_TIME (event that haven't been acknowledged for the amount of time in ms).
- `article_extractor.py` - The EventHub delegates actual event processing to **ArticleExtractor.extract** method. Which in case the `html` is present tries to extract from that and in case of failure downloads the article and tries extraction from that. The article extractor employs *Trafilatura* wrapped in a convenience wrapped *ArticleProcessor*, making mocking for tests simpler. Internally the ArticleExtractor employs `article_transformer` which transforms the extracted HTML and pure_text further to simplify the rendering and phonemizing the article down the line.
- `article_transformer.py` - Uses `lxml` to further process the extracted HTML on multiple steps of extraction.
- `conftest.py` - Mocks and fixtures for tests.
- `test_*.py` - Test files testing each of the component. Read more about the testing approach at [docs/testing.md](../docs/testing.md)

## testing

To run tests use `uv run pytest <test_file_name> -v`.
To run all test use `uv run pytest test_* -v`.
