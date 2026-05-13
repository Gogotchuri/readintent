import logging

from lxml import html as lxml_html


def replace_graphic_with_img(html: str) -> str:
	return html.replace('<graphic', '<img').replace('</graphic>', '</img>')


logger = logging.Logger = logging.getLogger(__name__)


class ArticleTransformer:
	"""
	Used to aid in transformation of the extracted article html to make it easier to run TTS and display in UI
	"""
	code_blocks: dict

	def __init__(self):
		self.code_blocks = {}

	def return_html_with_replaced_code_sections(self, raw_html: str) -> str:
		"""
		Extract code sections from the raw html and replace them with placeholders in the html
		We will swap them back in full later
		"""
		try:
			new_tree = lxml_html.fromstring(raw_html)
			for i, pre in enumerate(new_tree.xpath("//pre")):
				code_placeholder = f"__code_pre_PLACEHOLDER_{i}__"
				self.code_blocks[code_placeholder] = lxml_html.tostring(pre, method="html", pretty_print=True,
				                                                        encoding="unicode")  # TODO not sure if html is the best here, need to write code renderer on flutter first
				pre.getparent().replace(pre, lxml_html.fromstring(f"<p>{code_placeholder}</p>"))

			# There might be more code blocks in the html, we need to replace them too
			for i, code in enumerate(new_tree.xpath("//code")):
				code_placeholder = f"__code_code_PLACEHOLDER_{i}__"
				self.code_blocks[code_placeholder] = lxml_html.tostring(code, method="html", pretty_print=True, )

			return lxml_html.tostring(new_tree).decode("utf-8")
		except Exception as e:
			logger.error(f"Error replacing code sections: {e}")
			return raw_html

	def swap_code_placeholders_with_code_sections(self, html: str) -> str:
		try:
			for code_placeholder, code_section in self.code_blocks.items():
				html = html.replace(f"<p>{code_placeholder}</p>", code_section)
			tree = lxml_html.fromstring(html)
			for _, code in enumerate(tree.xpath("//code")):
				# Try to determine what language the code element cotains
				code_class = code.get("class", "")
				if "language-" in code_class:
					code_lang = code_class.split("language-")[1]
					code.set("data-lang", code_lang)
			html = lxml_html.tostring(tree).decode("utf-8")
		except Exception as e:
			logger.error(f"Error swapping code placeholders with code sections: {e}")

		return html

	def transform_extracted_html(self, html: str):
		"""
		Transform the article html to make it easy to display for our flutter app
		"""
		html = replace_graphic_with_img(html)
		html = self.swap_code_placeholders_with_code_sections(html)
		return html

	def transform_bare_extracted_html_for_pure(self, html: str) -> str:
		"""
		Prepare the article html for pure text extraction
		"""
		try:
			# Our TTS model doesn't differentiate between headers and the rest of the text, so we need to add punctuation to headers (h1, h2, h3, h4, h5)
			tree = lxml_html.fromstring(html)
			for h in tree.xpath("//h1|//h2|//h3|//h4|//h5"):
				if h.text is None or h.text.endswith("."):
					continue
				h.text = f"{h.text}."
			html = lxml_html.tostring(tree).decode("utf-8")
			# TTS models also don't read code particularly well.
			# We have placeholders and can replace them with how many lines of code they represent
			for code_placeholder, code_section in self.code_blocks.items():
				section_tree = lxml_html.fromstring(code_section)
				loc = section_tree.text_content().count("\n")
				# We should be fine with 2 lines of code, might be simple commands or one-liner, possible for TTS to read
				if loc <= 2:
					html = html.replace(f"<p>{code_placeholder}</p>", code_section)
					continue
				html = html.replace(code_placeholder, f"skipping section with {loc} lines of code");
		except Exception as e:
			logger.error(f"Error transforming extracted html for pure text: {e}")
		return html
