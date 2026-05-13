from article_transformer import ArticleTransformer, replace_graphic_with_img


def _make_transformer():
	return ArticleTransformer()


def test_replace_graphic_with_img_replaces_tags():
	html = '<div><graphic src="img.png">content</graphic></div>'
	result = replace_graphic_with_img(html)
	assert "<graphic" not in result
	assert '<img src="img.png">' in result
	assert "</img>" in result


def test_replace_graphic_with_img_noop_when_no_graphic():
	html = "<div><p>Hello</p></div>"
	assert replace_graphic_with_img(html) == html


def test_replace_graphic_with_img_multiple():
	html = '<graphic src="a.png"></graphic><graphic src="b.png"></graphic>'
	result = replace_graphic_with_img(html)
	assert result.count("<img") == 2
	assert "<graphic" not in result


def test_return_html_replaces_single_pre_block():
	t = _make_transformer()
	html = "<div><p>text</p><pre><code>print('hi')</code></pre></div>"
	result = t.return_html_with_replaced_code_sections(html)
	assert "__code_pre_PLACEHOLDER_0__" in result
	assert "<pre>" not in result
	assert len(t.code_blocks) >= 1
	assert any("print" in v for v in t.code_blocks.values())


def test_return_html_replaces_multiple_pre_blocks():
	t = _make_transformer()
	html = "<div><pre>block1</pre><p>mid</p><pre>block2</pre></div>"
	result = t.return_html_with_replaced_code_sections(html)
	assert "__code_pre_PLACEHOLDER_0__" in result
	assert "__code_pre_PLACEHOLDER_1__" in result


def test_swap_sets_data_lang_from_class():
	t = _make_transformer()
	t.code_blocks = {
		"__code_pre_PLACEHOLDER_0__": '<pre><code class="language-python">x = 1</code></pre>'
	}
	html = "<div><p>__code_pre_PLACEHOLDER_0__</p></div>"
	result = t.swap_code_placeholders_with_code_sections(html)
	assert 'data-lang="python"' in result


def test_round_trip_extract_then_swap():
	t = _make_transformer()
	original_html = "<div><p>text</p><pre><code>hello()</code></pre></div>"
	stripped = t.return_html_with_replaced_code_sections(original_html)
	assert "PLACEHOLDER" in stripped
	restored = t.swap_code_placeholders_with_code_sections(stripped)
	assert "hello()" in restored
	assert "PLACEHOLDER" not in restored


def test_tts_headers_get_trailing_period():
	t = _make_transformer()
	html = "<div><h1>Introduction</h1><p>body</p></div>"
	result = t.transform_bare_extracted_html_for_pure(html)
	assert "Introduction." in result


def test_tts_headers_already_with_period_untouched():
	t = _make_transformer()
	html = "<div><h2>Period.</h2></div>"
	result = t.transform_bare_extracted_html_for_pure(html)
	assert "Period." in result
	assert "Period.." not in result


def test_tts_large_code_block_replaced_with_skip_message():
	t = _make_transformer()
	code = "line1\nline2\nline3\nline4\n"
	t.code_blocks = {"__code_pre_PLACEHOLDER_0__": f"<pre><code>{code}</code></pre>"}
	html = "<div><p>__code_pre_PLACEHOLDER_0__</p></div>"
	result = t.transform_bare_extracted_html_for_pure(html)
	assert "lines of code" in result


def test_tts_small_code_block_inlined():
	t = _make_transformer()
	code = "x = 1\n"
	t.code_blocks = {"__code_pre_PLACEHOLDER_0__": f"<pre><code>{code}</code></pre>"}
	html = "<div><p>__code_pre_PLACEHOLDER_0__</p></div>"
	result = t.transform_bare_extracted_html_for_pure(html)
	assert "x = 1" in result
	assert "skipping" not in result
