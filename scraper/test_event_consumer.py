import json

from article_extractor import ExtractedArticle, ExtractorError
from conftest import ScraperHubFixture


def _article(**overrides) -> ExtractedArticle:
    defaults = dict(
        title="Test", author="Author", date="2026-01-01",
        extracted_html="<p>hi</p>", pure_text="hi",
        url="https://example.com", categories=None, description=None, image=None,
    )
    defaults.update(overrides)
    return ExtractedArticle(**defaults)


def test_success_acks(hub: ScraperHubFixture):
    hub.mock.extract.return_value = _article()
    hub.send(article_id="42", url="http://example.com")
    hub.consume()
    assert hub.pending == 0
    assert hub.output[0]["article_id"] == "42"
    assert "result" in hub.output[0]

# Events that lack essential fields should be discarded, as there is no point in retrying them

def test_malformed_event_no_article_id(hub: ScraperHubFixture):
    hub.send(url="http://example.com")
    hub.consume()
    assert hub.pending == 0
    assert hub.output == []
    # No error is expected here, we lacked the main identifier and have no reasoable way to correlate the event correctly


def test_malformed_event_no_url(hub: ScraperHubFixture):
    hub.send(article_id="42")
    hub.consume()
    assert hub.pending == 0
    assert "missing url" in json.loads(hub.output[0]["error"])["msg"]


def test_failure_leaves_pending(hub: ScraperHubFixture):
    hub.mock.extract.side_effect = Exception("timeout")
    hub.send(article_id="42", url="http://example.com")
    hub.consume()
    assert hub.pending == 1
    assert hub.output == []


def test_extractor_error_leaves_pending(hub: ScraperHubFixture):
    hub.mock.extract.return_value = ExtractorError("not readerable")
    hub.send(article_id="42", url="http://example.com")
    hub.consume()
    assert hub.pending == 1
    assert hub.output == []


def test_retry_sweep_retries_idle_message(hub: ScraperHubFixture):
    # Fail on the first call, return article on second
    hub.mock.extract.side_effect = [Exception("transient"), _article()]
    hub.send(article_id="50", url="http://example.com")
    hub.consume()
    assert hub.pending == 1
    hub.run_retry_sweep()
    assert hub.pending == 0
    assert hub.output[0]["article_id"] == "50"


def test_retry_sweep_gives_up_at_max(hub: ScraperHubFixture):
    hub.mock.extract.side_effect = Exception("persistent")
    hub.conf.max_retries = 2
    hub.send(article_id="60", url="http://example.com")
    hub.consume()
    hub.bump_delivery_count(2)
    hub.run_retry_sweep()
    assert hub.pending == 0
    assert "max retries exceeded" in json.loads(hub.output[0]["error"])["msg"]
