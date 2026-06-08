import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:readintent_flutter/core/theme/app_colors.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/presentation/add_article_dialog.dart";
import "package:readintent_flutter/features/articles/providers/articles_provider.dart";
import "package:readintent_flutter/features/settings/presentation/font_size_button.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

class ArticlesScreen extends ConsumerStatefulWidget {
  final ArticleView view;
  const ArticlesScreen({super.key, required this.view});
  @override
  ConsumerState<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends ConsumerState<ArticlesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Detect scroll near the bottom and load more if needed
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(articlesProvider(widget.view).notifier).loadMore();
    }
  }

  String get _title => switch (widget.view) {
    ArticleView.inbox => "Inbox",
    ArticleView.favorite => "Favorite",
    ArticleView.archive => "Archive",
  };

  ({IconData icon, String title, String subtitle}) get _emptyState =>
      switch (widget.view) {
        ArticleView.inbox => (
          icon: Icons.inbox_outlined,
          title: "No articles yet",
          subtitle: "Tap + to add your first article",
        ),
        ArticleView.favorite => (
          icon: Icons.star_outline,
          title: "No favorites yet",
          subtitle: "Swipe an article to favorite it",
        ),
        ArticleView.archive => (
          icon: Icons.archive_outlined,
          title: "Archive is empty",
          subtitle: "Swipe an article to archive it",
        ),
      };

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(articlesProvider(widget.view));
    return Scaffold(
      appBar: AppBar(title: Text(_title), actions: const [FontSizeButton()]),
      floatingActionButton:
          widget.view == ArticleView.inbox ||
              widget.view == ArticleView.favorite ||
              widget.view == ArticleView.archive
          ? FloatingActionButton(
              // Unique per view: all three ArticlesScreens are mounted at once
              // inside the shell, so a shared default hero tag collides.
              heroTag: "add-article-fab-${widget.view.name}",
              onPressed: () => showDialog(
                context: context,
                builder: (_) => const AddArticleDialog(),
              ),
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.add),
            )
          : null,
      body: articlesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Error: $error"),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(articlesProvider(widget.view).notifier).refresh(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
        data: (state) {
          if (state.articles.isEmpty) {
            final empty = _emptyState;
            final muted = Theme.of(context).colorScheme.onSurfaceVariant;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(empty.icon, size: 64, color: muted),
                  const SizedBox(height: 16),
                  Text(
                    empty.title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: muted),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    empty.subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(articlesProvider(widget.view).notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: state.articles.length + (state.isLoading ? 1 : 0),
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index >= state.articles.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final article = state.articles[index];
                final isProcessing = article.status == "processing";
                return isProcessing
                    ? _ProcessingArticleTile(article: article)
                    : _ArticleTile(article: article, view: widget.view);
              },
            ),
          );
        },
      ),
    );
  }
}

// A single list action (favorite / archive / delete)
class _TileAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color onColor;
  final Future<void> Function() run;
  const _TileAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onColor,
    required this.run,
  });
}

// --- Full article tile: title, description, author, date, image ---
// Swipe + long-press surface the list actions; both route through the shared update hub
class _ArticleTile extends ConsumerWidget {
  final articles_pb.ArticlePreview article;
  final ArticleView view;
  const _ArticleTile({required this.article, required this.view});

  bool get _isArchived =>
      ArticleListState.fromProto(article.listState) == ArticleListState.archive;

  String get _id => article.id.toInt().toString();

  Articles _actions(WidgetRef ref) => ref.read(articlesProvider(view).notifier);

  _TileAction _favoriteAction(BuildContext context, WidgetRef ref) =>
      _TileAction(
        icon: article.isFavorite ? Icons.star_outline : Icons.star,
        label: article.isFavorite ? "Unfavorite" : "Favorite",
        color: context.appColors.favorite,
        onColor: context.appColors.onFavorite,
        run: () =>
            _actions(ref).setArticleState(_id, isFavorite: !article.isFavorite),
      );

  _TileAction _archiveAction(BuildContext context, WidgetRef ref) =>
      _TileAction(
        icon: _isArchived ? Icons.unarchive : Icons.archive,
        label: _isArchived ? "Unarchive" : "Archive",
        color: _isArchived
            ? context.appColors.archived
            : context.appColors.archive,
        onColor: context.appColors.onArchive,
        run: () => _actions(ref).setArticleState(
          _id,
          listState: _isArchived
              ? ArticleListState.inbox
              : ArticleListState.archive,
        ),
      );

  _TileAction _deleteAction(BuildContext context, WidgetRef ref) => _TileAction(
    icon: Icons.delete_outline,
    label: "Delete",
    color: Theme.of(context).colorScheme.error,
    onColor: Theme.of(context).colorScheme.onError,
    run: () => _actions(ref).deleteArticle(_id),
  );

  ({_TileAction right, _TileAction left}) _swipeActions(
    BuildContext context,
    WidgetRef ref,
  ) => view == ArticleView.favorite
      ? (
          right: _archiveAction(context, ref),
          left: _favoriteAction(context, ref),
        )
      : (
          right: _favoriteAction(context, ref),
          left: _archiveAction(context, ref),
        );

  Widget _swipeBackground(_TileAction a, {required bool swipeRight}) {
    return Container(
      color: a.color,
      alignment: swipeRight ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(a.icon, color: a.onColor),
          const SizedBox(width: 8),
          Text(a.label, style: TextStyle(color: a.onColor)),
        ],
      ),
    );
  }

  void _showActions(BuildContext context, WidgetRef ref) {
    final actions = [
      _favoriteAction(context, ref),
      _archiveAction(context, ref),
      _deleteAction(context, ref),
    ];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final a in actions)
                ListTile(
                  leading: Icon(a.icon, color: a.color),
                  title: Text(a.label),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    a.run();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swipe = _swipeActions(context, ref);
    return Dismissible(
      key: ValueKey(article.id.toInt()),
      background: _swipeBackground(swipe.right, swipeRight: true),
      secondaryBackground: _swipeBackground(swipe.left, swipeRight: false),
      confirmDismiss: (direction) async {
        final action = direction == DismissDirection.startToEnd
            ? swipe.right
            : swipe.left;
        await action.run();
        return false;
      },
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        title: Row(
          children: [
            if (article.isFavorite) ...[
              Icon(Icons.star, size: 16, color: context.appColors.favorite),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                article.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                article.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (article.author.isNotEmpty) ...[
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      article.author,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (article.date.isNotEmpty) ...[
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    article.date,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
            if (article.status == "failed") ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Processing failed",
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        // Image or null after the article, display broken indicator when image fails to load
        trailing: article.image.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: article.image,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : null,
        onTap: () => context.push("/articles/${article.id}"),
        onLongPress: () => _showActions(context, ref),
      ),
    );
  }
}

class _ProcessingArticleTile extends StatefulWidget {
  final articles_pb.ArticlePreview article;
  const _ProcessingArticleTile({required this.article});
  @override
  State<_ProcessingArticleTile> createState() => _ProcessingArticleTileState();
}

// Used to have animated state displaying when article isn't parsed yet
class _ProcessingArticleTileState extends State<_ProcessingArticleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final skeleton = scheme.surfaceContainerHighest.withValues(
          alpha: _animation.value,
        );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: skeleton,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: skeleton,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.article.url,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Processing...",
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.appColors.warning,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: skeleton,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
