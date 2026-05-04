import json
import logging
from concurrent.futures import ThreadPoolExecutor
from typing import cast
from unittest.mock import Mock

from article_extraction import ExtractedArticle
from config import Config
from event_consumer import EventHub


def _make_config() -> Config:
    return Config(
        stream_input_event="test:input",
        stream_output_event="test:output",
        consumer_group="test-group",
        consumer_name="test-consumer",
    )

def _make_hub(redis_db, extractor=None) -> tuple[EventHub, Config]:
    conf = _make_config()
    ext = extractor or Mock()
    hub = EventHub(conf, redis_db, ext)
    return hub, conf

def test_consumer_basic(redis_db, caplog):
    mock_extractor = Mock()
    mock_extractor.extract.return_value = ExtractedArticle(
        title="Test", author="Author", date="2026-01-01",
        extracted_html="<p>hi</p>", pure_text="hi",
        url="https://example.com", categories=None, description=None, image=None,
    )
    hub, conf = _make_hub(redis_db, mock_extractor)

    hub.ensure_group()

    hub.redis_client.xadd(conf.stream_input_event, {"article_id": "42", "url": "http://example.com"})
    with ThreadPoolExecutor(max_workers=2) as executor:
        hub._consume_single_event_batch(executor)

    # Make sure there were no errors
    assert [r for r in caplog.records if r.levelno >= logging.ERROR] == []

    # Check there is a result returned
    results = cast(dict, hub.redis_client.xread({conf.stream_output_event: "0-0"}, count=1, block=1000))
    assert results, "No results found in output stream"
    batch = results.get(conf.stream_output_event, [])
    assert batch, "No events found in output stream"
    events = batch[0]
    event_fields = events[0][1]
    assert event_fields.get("article_id") == "42", "article_id not passed through"
    result_data = event_fields.get("result")
    assert result_data, "No result field found in output event"
    result_unmarshalled = json.loads(result_data)
    assert result_unmarshalled['extracted_html'] == "<p>hi</p>", "Extracted HTML does not match expected value"