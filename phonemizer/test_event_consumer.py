import json
from unittest.mock import MagicMock


def _phoneme_result(**overrides) -> MagicMock:
    mock = MagicMock()
    defaults = {"graphemes": "hello", "phonemes": "hɛloʊ", "token_ids": [1], "token_meta": []}
    defaults.update(overrides)
    mock.to_dict.return_value = defaults
    return mock


def test_success_acks(hub):
    hub.mock.generate_phonemes.return_value = [_phoneme_result()]
    hub.send(article_id="99", result=json.dumps({"pure_text": "Hello!"}))
    hub.consume()
    assert hub.pending == 0
    assert hub.output[0]["article_id"] == "99"
    assert "result" in hub.output[0]


def test_malformed_event_no_article_id(hub):
    hub.send(result=json.dumps({"pure_text": "Hello"}))
    hub.consume()
    assert hub.pending == 0
    assert hub.output == []


def test_malformed_event_no_pure_text(hub):
    hub.send(article_id="99", result=json.dumps({"title": "no text here"}))
    hub.consume()
    assert hub.pending == 0
    assert "missing pure_text" in json.loads(hub.output[0]["error"])["msg"]


def test_malformed_event_invalid_json(hub):
    hub.send(article_id="99", result="not valid json{{{")
    hub.consume()
    assert hub.pending == 0
    assert "missing pure_text" in json.loads(hub.output[0]["error"])["msg"]


def test_failure_leaves_pending(hub):
    hub.mock.generate_phonemes.side_effect = Exception("model crash")
    hub.send(article_id="99", result=json.dumps({"pure_text": "Hello!"}))
    hub.consume()
    assert hub.pending == 1
    assert hub.output == []


def test_retry_sweep_retries_idle_message(hub):
    mock_result = _phoneme_result()
    hub.mock.generate_phonemes.side_effect = [Exception("transient"), [mock_result]]
    hub.send(article_id="50", result=json.dumps({"pure_text": "Hello!"}))
    hub.consume()
    assert hub.pending == 1
    hub.run_retry_sweep()
    assert hub.pending == 0
    assert hub.output[0]["article_id"] == "50"
    assert "result" in hub.output[0]


def test_retry_sweep_gives_up_at_max(hub):
    hub.mock.generate_phonemes.side_effect = Exception("persistent")
    hub.conf.max_retries = 2
    hub.send(article_id="60", result=json.dumps({"pure_text": "Hello!"}))
    hub.consume()
    hub.bump_delivery_count(2)
    hub.run_retry_sweep()
    assert hub.pending == 0
    assert "max retries exceeded" in json.loads(hub.output[0]["error"])["msg"]
