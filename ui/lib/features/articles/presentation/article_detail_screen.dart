import "dart:async";

import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:readintent_flutter/features/articles/providers/article_detail_provider.dart";
import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

class ArticleDetailScreen extends ConsumerStatefulWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
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
    // User scrolled manually — pause auto-scroll for 5 seconds
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
    if (sentenceIndex <= 3) sentenceIndex = 0; // Show a few sentences before the current one for context

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
        .saveArticleProgress(articleId: widget.articleId, scrollPosition: fraction);
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
    final activeSentenceIndex = ref.watch(activePlayerProvider.select((s) => s.activeSentenceIndex));
    final syncEnabled = ref.watch(activePlayerProvider.select((s) => s.syncEnabled));

    // Auto-scroll when sentence changes and sync is enabled
    ref.listen(activePlayerProvider.select((s) => s.activeSentenceIndex), (prev, next) {
      if (syncEnabled && next != null) {
        _autoScrollToSentence(next);
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(articleAsync.asData?.value.title ?? "Article")),
      body: articleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(articleDetailProvider(widget.articleId)),
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

          return SingleChildScrollView(
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
                    if (attr != null && int.tryParse(attr) == activeSentenceIndex) {
                      return {"background-color": "rgba(255, 255, 20, 0.4)"};
                    }
                    return null;
                  },
                ),
              ],
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
        Text(article.title, style: theme.headlineSmall),
        const SizedBox(height: 8),
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
                color: Colors.grey[200],
                child: Icon(Icons.broken_image_outlined, size: 48, color: Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            if (article.author.isNotEmpty) ...[
              Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  article.author,
                  overflow: TextOverflow.ellipsis,
                  style: theme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 16),
            ],
            if (article.date.isNotEmpty) ...[
              Icon(Icons.calendar_today_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(article.date, style: theme.bodySmall?.copyWith(color: Colors.grey[600])),
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
//TODO
// import 'package:flutter/material.dart';
// import 'package:flutter_highlight/flutter_highlight.dart';
// import 'package:flutter_highlight/themes/github.dart'; // Choose a theme
// import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

// class CodeHighlightingHtml extends StatelessWidget {
//   final String htmlContent = '''
//     <p>Check out this code:</p>
//     <pre><code class="language-dart">void main() {
//   print('Hello, Flutter!');
// }</code></pre>
//   ''';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Code Highlighting")),
//       body: SingleChildScrollView(
//         child: HtmlWidget(
//           htmlContent,
//           customWidgetBuilder: (element) {
//             // Identify <pre> tags (or <code> tags)
//             if (element.localName == 'pre') {
//               // Extract the raw text code from the HTML element
//               final String code = element.text;

//               // Return a high-performance highlight widget
//               return Container(
//                 padding: EdgeInsets.all(8),
//                 child: HighlightView(
//                   code,
//                   language: 'dart', // Set language
//                   theme: githubTheme, // Set theme
//                   textStyle: TextStyle(fontFamily: 'monospace'),
//                 ),
//               );
//             }
//             return null; // Render other tags normally
//           },
//         ),
//       ),
//     );
//   }
// }
