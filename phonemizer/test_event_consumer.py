import json
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import cast
from unittest.mock import Mock

from tts.pipeline import PhonemizerPipeline
from config import Config
from event_consumer import EventHub


def _make_config() -> Config:
    return Config(
        stream_input_event="test:input",
        stream_output_event="test:output",
        consumer_group="test-group",
        consumer_name="test-consumer",
    )

def _make_hub(redis_db, phonemizer=None) -> tuple[EventHub, Config]:
    conf = _make_config()
    phon = phonemizer or Mock()
    hub = EventHub(conf, redis_db, phon)
    return hub, conf

def test_consumer_basic(redis_db, caplog):
    hub, conf = _make_hub(redis_db, PhonemizerPipeline())

    hub.ensure_group()

    hub.redis_client.xadd(conf.stream_input_event, {"result": json.dumps({"pure_text": "Hello world!"})})
    hub._consume_single_event_batch()

    # Make sure there were no errors
    assert [r for r in caplog.records if r.levelno >= logging.ERROR] == []

    # Check there is a result returned
    results = cast(dict, hub.redis_client.xread({conf.stream_output_event: "0-0"}, count=1, block=1000))
    assert results, "No results found in output stream"
    batch = results.get(conf.stream_output_event, [])
    assert batch, "No events found in output stream"
    events = batch[0]
    result_data = events[0][1].get("result")
    assert result_data, "No result field found in output event"
    result_unmarshalled = json.loads(result_data)
    assert result_unmarshalled, "Result data is not valid JSON"