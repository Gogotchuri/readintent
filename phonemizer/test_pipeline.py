from unittest.mock import MagicMock

import pytest

from tts.pipeline import PhonemizerPipeline, PhonemizerResult, TokenMeta
from tts.vocab import VOCAB


def _make_token(text, phonemes, whitespace=""):
    tok = MagicMock()
    tok.text = text
    tok.phonemes = phonemes
    tok.whitespace = whitespace
    return tok


def _make_result(graphemes, phonemes, tokens):
    r = MagicMock()
    r.graphemes = graphemes
    r.phonemes = phonemes
    r.tokens = tokens
    return r


@pytest.fixture
def pipeline():
    mock_kpipeline = MagicMock()
    p = PhonemizerPipeline(mock_kpipeline)
    return p, mock_kpipeline

# Happy paths for sentence complete generations, single and multiple

def test_single_sentence(pipeline):
    p, mock_kp = pipeline
    tokens = [_make_token("hello", "hɛloʊ", " ")]
    mock_kp.return_value = iter([_make_result("hello", "hɛloʊ", tokens)])

    results = p.generate_phonemes("hello")

    assert len(results) == 1
    assert results[0].graphemes == "hello"
    assert results[0].phonemes == "hɛloʊ"
    assert results[0].token_ids == [0] + [VOCAB[c] for c in "hɛloʊ" if c in VOCAB] + [0]
    assert len(results[0].token_meta) == 1
    assert results[0].token_meta[0].text == "hello"
    assert results[0].token_meta[0].has_whitespace is True


def test_multiple_sentences(pipeline):
    p, mock_kp = pipeline
    r1 = _make_result("Hi.", "haI.", [_make_token("Hi", "haI", " ")])
    r2 = _make_result("Bye.", "baI.", [_make_token("Bye", "baI", "")])
    mock_kp.return_value = iter([r1, r2])

    results = p.generate_phonemes("Hi. Bye.")

    assert len(results) == 2
    assert results[0].graphemes == "Hi."
    assert results[1].graphemes == "Bye."
    assert results[1].token_meta[0].has_whitespace is False


# Check the correctness of the token meta generation
def test_token_ids_match_vocab(pipeline):
    p, mock_kp = pipeline
    phonemes = "hɛloʊ"
    mock_kp.return_value = iter([_make_result("hello", phonemes, [])])

    results = p.generate_phonemes("hello")

    expected_ids = [0] + [VOCAB[c] for c in phonemes if c in VOCAB] + [0]
    assert results[0].token_ids == expected_ids


def test_token_meta_phoneme_len(pipeline):
    p, mock_kp = pipeline
    # "hɛl" has 3 chars all in VOCAB
    tokens = [_make_token("hel", "hɛl", "")]
    mock_kp.return_value = iter([_make_result("hel", "hɛl", tokens)])

    results = p.generate_phonemes("hel")

    assert results[0].token_meta[0].phoneme_len == 3


def test_token_meta_whitespace(pipeline):
    p, mock_kp = pipeline
    tokens = [
        _make_token("word1", "wɜːd", " "),
        _make_token("word2", "wɜːd", ""),
    ]
    mock_kp.return_value = iter([_make_result("word1 word2", "wɜːd wɜːd", tokens)])

    results = p.generate_phonemes("word1 word2")

    assert results[0].token_meta[0].has_whitespace is True
    assert results[0].token_meta[1].has_whitespace is False

# Empty text is technically still a text
def test_empty_text(pipeline):
    p, mock_kp = pipeline
    mock_kp.return_value = iter([])

    results = p.generate_phonemes("")

    assert results == []

# Token meta can be empty and we should still acept such generated output
def test_no_tokens(pipeline):
    p, mock_kp = pipeline
    mock_kp.return_value = iter([_make_result("hello", "hɛloʊ", None)])

    results = p.generate_phonemes("hello")

    assert results[0].token_meta == []
    assert results[0].token_ids == [0] + [VOCAB[c] for c in "hɛloʊ" if c in VOCAB] + [0]


# We should ignore characters not in vocab, except little information loss
def test_phonemes_not_in_vocab(pipeline):
    p, mock_kp = pipeline
    phonemes = "h#@ɛ"  # '#' and '@' are not in VOCAB
    mock_kp.return_value = iter([_make_result("test", phonemes, [])])

    results = p.generate_phonemes("test")

    expected_ids = [0, VOCAB["h"], VOCAB["ɛ"], 0]
    assert results[0].token_ids == expected_ids


# Test serialization
def test_to_dict(pipeline):
    p, mock_kp = pipeline
    tokens = [_make_token("hi", "haI", " ")]
    mock_kp.return_value = iter([_make_result("hi", "haI", tokens)])

    results = p.generate_phonemes("hi")
    d = results[0].to_dict()

    assert d == {
        "graphemes": "hi",
        "phonemes": "haI",
        "token_ids": [0, VOCAB["h"], VOCAB["a"], VOCAB["I"], 0],
        "token_meta": [{"text": "hi", "phoneme_len": 3, "has_whitespace": True}],
    }
