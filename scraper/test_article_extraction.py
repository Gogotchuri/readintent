from unittest.mock import Mock
from article_extraction import ArticleExtractor, ExtractorError, ExtractedArticle, ArticleProcessor
from trafilatura.settings import Document

def _make_metadata(title="Title", author="Author", date="2026-01-01", categories=None, description=None, image=None) -> Document:
    doc = Document()
    doc.title, doc.author, doc.date = title, author, date
    doc.categories, doc.description, doc.image = categories, description, image
    return doc

def _make_mock_processor(**overrides) -> Mock:
    mock = Mock(spec=ArticleProcessor)
    mock.fetch_url.return_value = overrides.get("fetch_url", "<html>content</html>")
    mock.is_probably_readerable.return_value = overrides.get("is_readerable", True)
    mock.extract_metadata.return_value = overrides.get("metadata", _make_metadata())
    mock.extract_text.return_value = overrides.get("extract_text", "plain text")
    mock.extract.return_value = overrides.get("extract_html", "<p>html</p>")
    return mock

URL = "https://example.com/article"


def test_extract_success():
    proc = _make_mock_processor()
    result = ArticleExtractor(proc).extract(URL)
    assert isinstance(result, ExtractedArticle)
    assert result.url == URL
    assert result.title == "Title"
    assert result.author == "Author"
    assert result.date == "2026-01-01"
    assert result.pure_text == "plain text"
    assert result.extracted_html == "<p>html</p>"

# Test cases below test exception and abscence of the return value at each stage of the extraction

def test_download_empty():
    proc = _make_mock_processor(fetch_url=None)
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(fetch_url="")
    call_and_expect_extraction_error(proc)


def test_download_exception():
    proc = _make_mock_processor()
    proc.fetch_url.side_effect = Exception("network error")
    call_and_expect_extraction_error(proc)


def test_not_readerable():
    proc = _make_mock_processor(is_readerable=False)
    call_and_expect_extraction_error(proc)


def test_readerable_exception():
    proc = _make_mock_processor()
    proc.is_probably_readerable.side_effect = Exception("parse error")
    call_and_expect_extraction_error(proc)


def test_metadata_missing():
    proc = _make_mock_processor(metadata=None)
    call_and_expect_extraction_error(proc)


def test_metadata_no_title():
    proc = _make_mock_processor(metadata=_make_metadata(title=None))
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(metadata=_make_metadata(title=""))
    call_and_expect_extraction_error(proc)


def test_metadata_no_author():
    proc = _make_mock_processor(metadata=_make_metadata(author=None))
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(metadata=_make_metadata(author=""))
    call_and_expect_extraction_error(proc)


def test_metadata_no_date():
    proc = _make_mock_processor(metadata=_make_metadata(date=None))
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(metadata=_make_metadata(date=""))
    call_and_expect_extraction_error(proc)


def test_metadata_exception():
    proc = _make_mock_processor()
    proc.extract_metadata.side_effect = Exception("metadata parse error")
    call_and_expect_extraction_error(proc)


def test_pure_text_empty():
    proc = _make_mock_processor(extract_text=None)
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(extract_text="")
    call_and_expect_extraction_error(proc)


def test_pure_text_exception():
    proc = _make_mock_processor()
    proc.extract_text.side_effect = Exception("text extraction error")
    call_and_expect_extraction_error(proc)


def test_html_extraction_empty():
    proc = _make_mock_processor(extract_html=None)
    call_and_expect_extraction_error(proc)
    proc = _make_mock_processor(extract_html="")
    call_and_expect_extraction_error(proc)


def test_html_extraction_exception():
    proc = _make_mock_processor()
    proc.extract.side_effect = Exception("html extraction error")
    call_and_expect_extraction_error(proc)

def call_and_expect_extraction_error(proc: Mock):
    result = ArticleExtractor(proc).extract(URL)
    assert isinstance(result, ExtractorError)
