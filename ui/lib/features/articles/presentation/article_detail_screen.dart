import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_highlight/flutter_highlight.dart";
import "package:flutter_highlight/themes/atom-one-dark.dart";
import "package:flutter_highlight/themes/github.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:readintent_flutter/features/articles/presentation/auto_marquee.dart";
import "package:readintent_flutter/features/articles/providers/article_detail_provider.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/features/settings/presentation/font_size_button.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleDetailScreen> createState() =>
      _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends ConsumerState<ArticleDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  final WidgetFactory _htmlWidgetFactory = WidgetFactory();
  Timer? _scrollDebounce;
  Timer? _manualScrollPause;
  bool _scrollRestored = false;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _saveScrollPosition();
    _scrollDebounce?.cancel();
    _manualScrollPause?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // User scrolled manually - pause auto-scroll for 5 seconds
    if (!_isAutoScrolling) {
      _manualScrollPause?.cancel();
      _manualScrollPause = Timer(const Duration(seconds: 5), () {
        _manualScrollPause = null;
      });
    }

    _scrollDebounce?.cancel();
    _scrollDebounce = Timer(const Duration(seconds: 3), _saveScrollPosition);
  }

  void _autoScrollToSentence(int sentenceIndex) {
    if (_manualScrollPause?.isActive ?? false) return;
    if (!_scrollController.hasClients) return;
    if (sentenceIndex <= 3)
      sentenceIndex =
          0; // Show a few sentences before the current one for context

    _isAutoScrolling = true;
    _htmlWidgetFactory
        .onTapAnchorWrapper("sentence-${sentenceIndex - 3}")
        .then((_) => _isAutoScrolling = false);
  }

  void _saveScrollPosition() {
    if (!_scrollController.hasClients) return;
    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) return;
    final fraction = (_scrollController.offset / maxExtent).clamp(0.0, 1.0);
    ref
        .read(articleRepositoryProvider)
        .saveArticleProgress(
          articleId: widget.articleId,
          scrollPosition: fraction,
        );
  }

  void _restoreScrollPosition(double scrollPosition) {
    if (_scrollRestored || scrollPosition <= 0) return;
    _scrollRestored = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (maxExtent <= 0) return;
      _scrollController.jumpTo(scrollPosition * maxExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final articleAsync = ref.watch(articleDetailProvider(widget.articleId));
    final activeSentenceIndex = ref.watch(
      activePlayerProvider.select((s) => s.activeSentenceIndex),
    );
    final syncEnabled = ref.watch(
      activePlayerProvider.select((s) => s.syncEnabled),
    );

    // Active-sentence highlight while TTS plays
    final highlightCss = Theme.of(context).brightness == Brightness.dark
        ? "#7B2CBF"
        : "#F7B267";

    // Auto-scroll when sentence changes and sync is enabled
    ref.listen(activePlayerProvider.select((s) => s.activeSentenceIndex), (
      prev,
      next,
    ) {
      if (syncEnabled && next != null) {
        _autoScrollToSentence(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: AutoMarquee(text: articleAsync.asData?.value.title ?? "Article"),
        actions: const [FontSizeButton()],
      ),
      body: articleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(articleDetailProvider(widget.articleId)),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (article) {
          // Show the player widget for articles with TTS data
          if (article.phonemizerData.isNotEmpty) {
            Future.microtask(() {
              ref.read(activePlayerProvider.notifier).loadArticle(article);
            });
          }

          // Restore scroll position from server
          _restoreScrollPosition(article.scrollPosition);

          // SelectionArea makes the article body text selectable / copyable.
          return SelectionArea(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ArticleHeader(article: article),
                  const Divider(height: 32),
                  HtmlWidget(
                    article.extractedHtml,
                    factoryBuilder: () => _htmlWidgetFactory,
                    rebuildTriggers: [activeSentenceIndex],
                    customStylesBuilder: (element) {
                      final attr = element.attributes["data-sentence"];
                      if (attr != null &&
                          int.tryParse(attr) == activeSentenceIndex) {
                        return {"background-color": highlightCss};
                      }
                      return null;
                    },
                    // Render <pre> code blocks with syntax highlighting instead of plain text.
                    customWidgetBuilder: (element) {
                      if (element.localName != "pre") return null;
                      final codeElement =
                          element.querySelector("code") ?? element;
                      final code = codeElement.text;
                      // Single-line snippets read better as an inline code "word"
                      // with a background than as a full bordered block.
                      if (!code.trim().contains("\n")) {
                        return _InlineCode(code: code.trim());
                      }
                      final language = _detectLanguage(
                        classes: [...codeElement.classes, ...element.classes],
                        dataLang:
                            codeElement.attributes["data-lang"] ??
                            element.attributes["data-lang"],
                      );
                      return _CodeBlock(code: code, language: language);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ArticleHeader extends StatelessWidget {
  final articles_pb.Article article;
  const _ArticleHeader({required this.article});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (article.image.isNotEmpty) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: article.image,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: double.infinity,
                height: 200,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            if (article.author.isNotEmpty) ...[
              Icon(
                Icons.person_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  article.author,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (article.date.isNotEmpty) ...[
              Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                article.date,
                style: theme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
        if (article.categories.isNotEmpty) ...[
          // TODO categories
        ],
      ],
    );
  }
}

/// Languages registered by the `highlight` package that we map article code
/// blocks onto. Anything not in this set falls back to "plaintext" so
/// HighlightView never throws on an unknown language.
const Set<String> _knownLanguages = {
  "bash",
  "c",
  "cpp",
  "csharp",
  "css",
  "dart",
  "diff",
  "go",
  "graphql",
  "html",
  "java",
  "javascript",
  "json",
  "kotlin",
  "less",
  "lua",
  "makefile",
  "markdown",
  "objectivec",
  "perl",
  "php",
  "plaintext",
  "python",
  "ruby",
  "rust",
  "scala",
  "scss",
  "shell",
  "sql",
  "swift",
  "typescript",
  "xml",
  "yaml",
};

/// Common shorthand/aliases used in `language-xxx` class names.
const Map<String, String> _languageAliases = {
  "js": "javascript",
  "ts": "typescript",
  "py": "python",
  "rb": "ruby",
  "sh": "shell",
  "yml": "yaml",
  "c++": "cpp",
  "cs": "csharp",
  "objc": "objectivec",
  "html5": "html",
};

/// Resolves a highlight language for a code block. Prefers the `language-xxx` /
/// `lang-xxx` classes on the `<pre>` or its child `<code>`, then falls back to a
/// `data-lang` attribute, and finally "plaintext".
String _detectLanguage({required Iterable<String> classes, String? dataLang}) {
  for (final cls in classes) {
    final lower = cls.toLowerCase();
    if (lower.startsWith("language-") || lower.startsWith("lang-")) {
      final normalized = _normalizeLanguage(
        lower.substring(lower.indexOf("-") + 1),
      );
      if (normalized != null) return normalized;
    }
  }
  if (dataLang != null) {
    final normalized = _normalizeLanguage(dataLang.toLowerCase().trim());
    if (normalized != null) return normalized;
  }
  return "plaintext";
}

String? _normalizeLanguage(String raw) {
  final normalized = _languageAliases[raw] ?? raw;
  return _knownLanguages.contains(normalized) ? normalized : null;
}

/// Syntax-highlighted, horizontally-scrollable code block
class _CodeBlock extends StatelessWidget {
  final String code;
  final String language;
  const _CodeBlock({required this.code, required this.language});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: HighlightView(
          code,
          language: language,
          theme: isDark ? atomOneDarkTheme : githubTheme,
          padding: const EdgeInsets.all(12),
          textStyle: const TextStyle(fontFamily: "monospace", fontSize: 13),
        ),
      ),
    );
  }
}

/// A one-line code snippet rendered as a compact, content-sized "word" with a
/// monospace font and subtle background (like inline `<code>`).
class _InlineCode extends StatelessWidget {
  final String code;
  const _InlineCode({required this.code});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          code,
          style: const TextStyle(fontFamily: "monospace", fontSize: 13),
        ),
      ),
    );
  }
}
