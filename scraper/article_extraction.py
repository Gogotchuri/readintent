import dataclasses
import logging
import threading
from typing import Optional, cast

import trafilatura
from trafilatura.settings import Extractor, Document
from trafilatura.readability_lxml import is_probably_readerable, HtmlElement
from urllib.parse import urlparse


class ExtractorError(Exception):
    """Custom exception for article extraction errors"""
    pass


@dataclasses.dataclass
class ExtractedArticle:
    """Dataclass to store the extracted article content"""
    url: str
    title: str
    author: str
    date: str
    extracted_html: str
    pure_text: str
    categories: Optional[str]
    description: Optional[str]
    image: Optional[str]


DEFAULT_EXTRACTOR_OPTIONS = Extractor(output_format="html", formatting=True, links=True, images=True, tables=True,
                                      comments=False, precision=False)

class ArticleExtractor:
    def __init__(self) -> None:
        """Initialize the ArticleExtractor"""
        self._logger: logging.Logger = logging.getLogger(__name__)
        # Lock to ensure thread-safe access to the origin_locks dictionary
        self._lock_guard: threading.Lock = threading.Lock()
        # Dictionary to store origin locks for each origin to avoid spamming the same origin
        self._origin_locks: dict[str, threading.Lock] = {}

    def _get_origin_lock(self, origin: str) -> threading.Lock:
        """Get or create a lock for the given origin to prevent spamming the same origin"""
        with self._lock_guard:
            if origin not in self._origin_locks:
                self._origin_locks[origin] = threading.Lock()
            return self._origin_locks[origin]

    def _is_readerable(self, html: HtmlElement | str | None) -> bool:
        """Check if the HTML is probably readerable using trafilatura's readability check"""
        if html is None:
            return False
        try:
            return is_probably_readerable(cast(HtmlElement, html))
        except Exception as e:
            self._logger.error(f"Error checking readability: {e}")
            return False

    def _extract_metadata(self, url: str, html: HtmlElement | str) -> Document | ExtractorError:
        """Extract metadata from the HTML using trafilatura's extraction options"""
        try:
            metadata = trafilatura.extract_metadata(html, url)
            if not metadata:
                self._logger.warning("Failed to extract metadata")
                return ExtractorError("Failed to extract metadata")
            if not metadata.title:
                self._logger.warning("Metadata does not have a title")
                return ExtractorError("Metadata does not have a title")
            if not metadata.author:
                self._logger.warning("Metadata does not have an author")
                return ExtractorError("Metadata does not have an author")
            if not metadata.date:
                self._logger.warning("Metadata does not have a date")
                return ExtractorError("Metadata does not have a date")
            return metadata
        except Exception as e:
            self._logger.error(f"Error extracting metadata: {e}")
            return ExtractorError(f"Error extracting metadata: {e}")

    def _extract_pure_text(self, html: HtmlElement | str) -> str | ExtractorError:
        """Extract pure text content from the HTML using trafilatura's extraction options"""
        try:
            extracted = trafilatura.extract(html, output_format="txt", include_comments=False)
            if not extracted:
                self._logger.warning("Failed to extract pure text")
                return ExtractorError("Failed to extract pure text")
            return extracted.strip()
        except Exception as e:
            self._logger.error(f"Error extracting pure text: {e}")
            return ExtractorError(f"Error extracting pure text: {e}")

    def _extract_formatted_html(self, html: HtmlElement | str) -> str | ExtractorError:
        """Extract formatted HTML content from the HTML using trafilatura's extraction options"""
        try:
            extracted = trafilatura.extract(html, options=DEFAULT_EXTRACTOR_OPTIONS)
            if not extracted:
                self._logger.warning("Failed to extract formatted HTML")
                return ExtractorError("Failed to extract formatted HTML")
            return extracted.strip()
        except Exception as e:
            self._logger.error(f"Error extracting formatted HTML: {e}")
            return ExtractorError(f"Error extracting formatted HTML: {e}")

    def _download_content(self, url: str) -> str | ExtractorError:
        """Locking the origin and downloading the content from the given URL using trafilatura"""
        origin = urlparse(url).netloc
        origin_lock = self._get_origin_lock(origin)
        with origin_lock:
            self._logger.info(f"Downloading content from {url}")
            try:
                downloaded = trafilatura.fetch_url(url)
                if not downloaded:
                    self._logger.warning(f"Failed to download content from {url}")
                    return ExtractorError(f"Failed to download content from {url}")
                return downloaded
            except Exception as e:
                self._logger.error(f"Error downloading content from {url}: {e}")
                return ExtractorError(f"Error downloading content from {url}: {e}")

    def extract(self, url: str) -> ExtractedArticle | ExtractorError:
        """Extract the article content from the given URL using trafilatura"""
        downloaded = self._download_content(url)
        if isinstance(downloaded, ExtractorError):
            return downloaded

        if not self._is_readerable(downloaded):
            self._logger.warning(f"Content from {url} is not readerable")
            return ExtractorError(f"Content from {url} is not readerable")

        metadata = self._extract_metadata(url, downloaded)
        if isinstance(metadata, ExtractorError):
            return metadata

        pure_text = self._extract_pure_text(downloaded)
        if isinstance(pure_text, ExtractorError):
            return pure_text

        formatted_html = self._extract_formatted_html(downloaded)
        if isinstance(formatted_html, ExtractorError):
            return formatted_html

        categories = ""
        if metadata.categories is not None:
            categories = ",".join(metadata.categories)

        return ExtractedArticle(
            title=metadata.title or "",
            author=metadata.author or "",
            date=metadata.date or "",
            categories=metadata.categories,
            description=metadata.description,
            image=metadata.image,
            extracted_html=formatted_html,
            pure_text=pure_text,
            url=url
        )
