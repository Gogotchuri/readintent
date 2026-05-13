import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart";
import "package:readintent_flutter/features/articles/presentation/article_player_widget.dart";
import "package:readintent_flutter/features/articles/providers/article_detail_provider.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as articles_pb;

class ArticleDetailScreen extends ConsumerWidget {
  final String articleId;
  const ArticleDetailScreen({super.key, required this.articleId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleDetailProvider(articleId));

    return articleAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text("Article")),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(title: const Text("Article")),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(articleDetailProvider(articleId)),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      ),
      data: (article) => Scaffold(
        appBar: AppBar(title: Text(article.title)),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ArticleHeader(article: article),
                    const Divider(height: 32),
                    HtmlWidget(article.extractedHtml),
                  ],
                ),
              ),
            ),
            if (article.phonemizerData.isNotEmpty) ArticlePlayerWidget(article: article),
          ],
        ),
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
