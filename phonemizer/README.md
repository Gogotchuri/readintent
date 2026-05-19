# Phonemizer for Read Intent

This directory includes self-contained Python service for generating phonemes for articles.

## Project Setup
This project uses tools from [astral.sh](https://docs.astral.sh/). Specifically `uv` for package management and `ty` for typechecking (Yes, this project uses type-checked Python).

### Configuration
Configuration is read and built in [`./config.py`](./config.py) from ENV variables and defaults.

Here are all of the ENV variables that can be set for this project:
- "PHONEMIZER_REDIS_URL" - Redis connection string
- "PHONEMIZER_STREAM_INPUT" - Redis Streams, input event name
- "PHONEMIZER_STREAM_OUTPUT" - Redis Streams, output event name
- "PHONEMIZER_CONSUMER_GROUP" - Redis Streams, consumer group
- "PHONEMIZER_CONSUMER_NAME" - Redis Streams, consumer name
- "PHONEMIZER_BLOCK_MS" - Redis Streams, time to block on events
- "PHONEMIZER_MIN_IDLE_TIME" - Redis Streams, min idle time for XAUTOCLAIM for failed requests
- "PHONEMIZER_MAX_RETRIES" - Max retries after failure (We will not retry if the input is malformed)

*To run this serice the Redis server should already be running*
### Run with Docker
From this directory build and run the Docker image with `docker build -t readintent_phonemizer . && docker run readintent_phonemizer`

### Run with `uv` (without Docker)
Install dependencies with `uv sync --locked` and run the main.py with `uv run main.py`

## I/O event structure
The input events for this are the output events of the **scraper** service. Each event must contain non-empty valid `article_id` (unique article integer identifier) and `result.pure_text` the cleaned text of the article to phonemize.
The generation of phonemes are done single-threaded with Kokoro-TTS.

The output events will always contain `article_id` and in case of *success* `result` with JSON marshalled array of [**PhonemizerResult**](./tts/pipeline.py). In case of *error*, the event will contain `error` property with `msg` property inside of it.

## Project Structure
- `main.py` - The main entry point. Sets up logging, redis client and starts consuming events.
- `config.py` - Build config from ENV and assign from default values when missing.
- `event_consumer.py` - Runs continuos loops concurrently (number of threads configured with MAX_WORKERS variable). Each loop consumes events from the configured Redis stream, group name, and consumer name. Runs the retry loop in a different thread with MAX_RETRIES and MIN_IDLE_TIME (event that haven't been acknowledged for the amount of time in ms).
- `pipeline/tts.py` - The EventHub delegates actual event processing to **PhonemizerPipeline.generate_phonemes** method. Which using Kokoro TTS generates phonemes.
- `conftest.py` - Mocks and fixtures for tests.
- `test_*.py` - Test files testing each of the component. Read more about the testing approach at [docs/testing.md](../docs/testing.md)

## testing

To run tests use `uv run pytest <test_file_name> -v`.
To run all test use `uv run pytest test_* -v`.
