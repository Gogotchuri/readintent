import dataclasses
import logging
import threading
from typing import Optional, Protocol, cast
from urllib.parse import urlparse

import trafilatura
from trafilatura.readability_lxml import is_probably_readerable, HtmlElement
from trafilatura.settings import Extractor, Document

from article_transformer import ArticleTransformer


class ExtractorError(Exception):
	"""Custom exception for article extraction errors"""
	pass


class ArticleProcessor(Protocol):
	"""Interface for abstracting the trafilatura and making it easy to mock it in tests"""

	def fetch_url(self, url: str) -> str | ExtractorError:
		"""Download and extract content from a URL"""
		...

	def is_probably_readerable(self, html: HtmlElement | str) -> bool:
		"""Check if content is probably readerable"""
		...

	def extract_metadata(self, html: HtmlElement | str, url: str) -> Document | None:
		"""Extract metadata from HTML content"""
		...

	def extract(self, html: HtmlElement | str, options: Extractor) -> str | None:
		"""Extract the article with specified options"""
		...

	def extract_text(self, html: HtmlElement | str) -> str | None:
		"""Extract Pure text specifically from the article html"""
		...


class TrafilaturaArticleProcessor(ArticleProcessor):
	"""Trafilatura implementation of ArticleProcessor"""

	def fetch_url(self, url: str) -> str | ExtractorError:
		try:
			content = trafilatura.fetch_url(url)
			return content if content else ExtractorError(f"Failed to fetch content from {url}")
		except Exception as e:
			return ExtractorError(f"Error fetching content from {url}: {e}")

	def is_probably_readerable(self, html: HtmlElement) -> bool:
		return is_probably_readerable(html)

	def extract_metadata(self, html: HtmlElement | str, url: str) -> Document | None:
		return trafilatura.extract_metadata(html, url)

	def extract(self, html: HtmlElement | str, options: Extractor) -> str | None:
		return trafilatura.extract(html, options=options)

	def extract_text(self, html: HtmlElement | str) -> str | None:
		return trafilatura.extract(html, output_format="txt", include_comments=False)


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


# Extractor default options:
# - Output format is html, keeping the basic structure of the article
# - Formatting is kept on a basic level and also includes links, images and tables
# - We are not interested in comment extraction
# - And we want to extract article with less focus on precision. If some of the content doesn't get extracted, that is better than nothing
DEFAULT_EXTRACTOR_OPTIONS = Extractor(output_format="html", formatting=True, links=True, images=True, tables=True,
                                      comments=False, precision=False)


class ArticleExtractor:
	"""
	Service for handling article extraction from URL.
	Uses Trafilatura for article download and content extraction
	"""

	def __init__(self, processor: ArticleProcessor | None = None) -> None:
		"""Initialize the ArticleExtractor"""
		# If we havent passed the processor we should initialize the trafilatura processor by default
		self._processor: ArticleProcessor = processor or TrafilaturaArticleProcessor()
		self._logger: logging.Logger = logging.getLogger(__name__)
		# Lock to ensure thread-safe access to the origin_locks dictionary
		self._lock_guard: threading.Lock = threading.Lock()
		# Dictionary to store origin locks for each origin to avoid spamming the same origin
		self._origin_locks: dict[str, threading.Lock] = {}

	def _get_origin_lock(self, origin: str) -> threading.Lock:
		"""
		Get or create a lock for the given origin to prevent spamming the same origin.
		This is done per service-instance level. We make the assumption that we won't have many concurrent
		services on the same server, to cause any problems with throttling
		"""
		with self._lock_guard:
			if origin not in self._origin_locks:
				self._origin_locks[origin] = threading.Lock()
			return self._origin_locks[origin]

	def _is_readerable(self, html: HtmlElement | str | None, pure_text: str) -> bool:
		"""Check if the HTML is probably readerable"""
		if html is None:
			return False
		try:
			if self._processor.is_probably_readerable(cast(HtmlElement, html)):
				return True

			if pure_text is not None and len(pure_text) > 300:
				return True

		except Exception as e:
			self._logger.error(f"Error checking readability: {e}")
			return False

	def _extract_metadata(self, url: str, html: HtmlElement | str) -> Document | ExtractorError:
		"""Extract metadata from the HTML"""
		try:
			metadata = self._processor.extract_metadata(html, url)
			if not metadata:
				self._logger.warning("Failed to extract metadata")
				return ExtractorError("Failed to extract metadata")
			if not metadata.title:
				self._logger.warning("Metadata does not have a title")
				return ExtractorError("Metadata does not have a title")
			return metadata
		except Exception as e:
			self._logger.error(f"Error extracting metadata: {e}")
			return ExtractorError(f"Error extracting metadata: {e}")

	def _extract_pure_text(self, html: HtmlElement | str) -> str | ExtractorError:
		"""
		Extract pure text content from the HTML using trafilatura's extraction options.
		This is must, since we want to generate audio from the text and the html format would make it impossible.
		"""
		try:
			extracted = self._processor.extract_text(html)
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
			extracted = self._processor.extract(html, options=DEFAULT_EXTRACTOR_OPTIONS)
			if not extracted:
				self._logger.warning("Failed to extract formatted HTML")
				return ExtractorError("Failed to extract formatted HTML")
			# We also need to replace <graphic> elements with imgs if present, not supported with UI
			# We will take the offchance that this will replace the intended text
			extracted = extracted.replace('<graphic', '<img').replace('</graphic>', '</img>')
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
				downloaded = self._processor.fetch_url(url)
				if not downloaded:
					self._logger.warning(f"Failed to download content from {url}")
					return ExtractorError(f"Failed to download content from {url}")
				return downloaded
			except Exception as e:
				self._logger.error(f"Error downloading content from {url}: {e}")
				return ExtractorError(f"Error downloading content from {url}: {e}")

	def _extract_from_html(self, url: str, html: str) -> ExtractedArticle | ExtractorError:
		"""Extract the article content from ready HTML. Can be either downloaded from the url or passed in as a parameter"""
		act = ArticleTransformer()
		# Strip all pre and code elements from downloaded content
		downloaded_no_code = act.return_html_with_replaced_code_sections(html)
		formatted_html = self._extract_formatted_html(downloaded_no_code)
		if isinstance(formatted_html, ExtractorError):
			return formatted_html
		# Before we alter the formatted html we can transform it in form we want for TTS
		html_for_pure_text = act.transform_bare_extracted_html_for_pure(formatted_html)
		# Replacing the placeholders with the actual code sections and graphic tags with img tags
		formatted_html = act.transform_extracted_html(formatted_html)

		pure_text = self._extract_pure_text(html_for_pure_text)
		if isinstance(pure_text, ExtractorError):
			return pure_text

		if not self._is_readerable(html, pure_text):
			self._logger.warning(f"Content from {url} is not readerable")
			return ExtractorError(f"Content from {url} is not readerable")

		metadata = self._extract_metadata(url, html)
		if isinstance(metadata, ExtractorError):
			return metadata

		categories = ""
		if metadata.categories is not None:
			categories = ",".join(metadata.categories)

		return ExtractedArticle(
			title=metadata.title or "",
			author=metadata.author or "",
			date=metadata.date or "",
			categories=categories,
			description=metadata.description,
			image=metadata.image,
			extracted_html=formatted_html,
			pure_text=pure_text,
			url=url
		)

	def extract(self, url: str, ready_html: str) -> ExtractedArticle | ExtractorError:
		"""
		Extract the article content from the given URL using trafilatura.
		We are either downloading or using passed in html, making sure the article is readable
		and extracting: Metadata, Pure Text and Formatted HTML in that order.
		"""
		if ready_html:
			res = self._extract_from_html(url, ready_html)
			# If we have html and we managed to extract the article from it, simply return it.
			# Otherwise, we will try to extract it from the url and if that also fails, return the error
			if isinstance(res, ExtractedArticle):
				self._logger.info(f"Successfully extracted article from ready_html for {url}")
				return res
		# Try ignoring the ready_html and extract from the url
		downloaded = self._download_content(url)
		if isinstance(downloaded, ExtractorError):
			return downloaded
		return self._extract_from_html(url, downloaded)
