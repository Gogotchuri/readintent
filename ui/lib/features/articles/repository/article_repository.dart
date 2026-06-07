import "dart:convert";

import "package:drift/drift.dart";
import "package:fixnum/fixnum.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:readintent_flutter/core/connectivity.dart";
import "package:readintent_flutter/core/database/app_database.dart";
import "package:readintent_flutter/features/articles/api/articles_client.dart";
import "package:readintent_flutter/features/articles/models/article_view.dart";
import "package:readintent_flutter/features/articles/presentation/html_sentence_mapper.dart";
import "package:readintent_flutter/features/tts/audio_generator.dart";
import "package:readintent_flutter/features/tts/sentence_builder.dart";
import "package:readintent_flutter/models/operation.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart"
    as articles_pb;

class ParseArticleResult {
  final bool queued;
  ParseArticleResult({required this.queued});
}

class ArticleRepository {
  final AppDatabase _db;
  final ArticlesClient _remote;
  final Ref _ref;

  ArticleRepository(this._db, this._remote, this._ref);

  bool get _isOnline => _ref.read(isOnlineProvider);

  /// Returns cached articles immediately, then fetches page 1 from server
  /// in background and calls [onUpdated] with the fresh response.
  Future<articles_pb.GetArticlesResponse> getArticles({
    int pageSize = 20,
    required ArticleView view,
    void Function(articles_pb.GetArticlesResponse updated)? onUpdated,
  }) async {
    // Return cached data immediately
    final cached = await _cachedPreviewsFor(view);
    final cachedProtos = cached.map(previewRowToProto).toList();

    // If online, fetch first page from server in background
    if (_isOnline) {
      fetchFreshArticles(pageSize, view)
          .then((result) {
            if (onUpdated != null && result != null) {
              onUpdated(result);
            }
          })
          .catchError((_) {});
    }

    return articles_pb.GetArticlesResponse(
      articles: cachedProtos,
      totalCount: cachedProtos.length,
    );
  }

  /// Reads the cached previews matching [view] (inbox/archive by list_state,
  /// favorite across both lists).
  Future<List<ArticlePreview>> _cachedPreviewsFor(ArticleView view) {
    switch (view) {
      case ArticleView.inbox:
        return _db.getPreviewsByView(listState: ArticleListState.dbInbox);
      case ArticleView.archive:
        return _db.getPreviewsByView(listState: ArticleListState.dbArchive);
      case ArticleView.favorite:
        return _db.getPreviewsByView(favoritesOnly: true);
    }
  }

  Future<void> _cacheFirstPage(articles_pb.GetArticlesResponse response) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final companions = <ArticlePreviewsCompanion>[];
    for (var i = 0; i < response.articles.length; i++) {
      companions.add(previewProtoToCompanion(response.articles[i], i, now));
    }
    await _db.replacePreviews(companions);
  }

  /// Checks the server for updates since [lastCheckedAt] (unix seconds).
  /// Returns null if offline.
  Future<articles_pb.CheckForUpdatesResponse?> checkForUpdates(
    int lastCheckedAt,
  ) async {
    if (!_isOnline) return null;
    return _remote.checkForUpdates(lastCheckedAt);
  }

  /// Fetches fresh articles from the server and caches them.
  /// Returns null if offline or on error.
  Future<articles_pb.GetArticlesResponse?> fetchFreshArticles(
    int pageSize,
    ArticleView view,
  ) async {
    if (!_isOnline) return null;
    try {
      final response = await _remote.getArticles(
        pageSize: pageSize,
        view: view,
      );
      await _cacheFirstPage(response);
      return response;
    } catch (_) {
      return null;
    }
  }

  /// Subscribes to server-pushed article updates. Errors flow to the caller so
  /// it can drive reconnect/backoff.
  Stream<articles_pb.StreamArticleUpdatesResponse> streamArticleUpdates() {
    return _remote.streamArticleUpdates();
  }

  /// Caches a single preview pushed over the stream, preserving its existing
  /// sortOrder if the row already exists (new articles sort to the top).
  Future<void> upsertPreviewFromUpdate(
    articles_pb.ArticlePreview preview,
  ) async {
    final existing = await _db.getPreview(preview.id.toInt());
    final sortOrder = existing?.sortOrder ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.upsertPreview(previewProtoToCompanion(preview, sortOrder, now));
  }

  /// Fetches the next page from the server (online only, no caching needed for pages beyond 1).
  Future<articles_pb.GetArticlesResponse> getArticlesPage({
    int pageSize = 20,
    String? pageToken,
    required ArticleView view,
  }) {
    return _remote.getArticles(
      pageSize: pageSize,
      pageToken: pageToken,
      view: view,
    );
  }

  Future<articles_pb.Article?> getArticle(
    String id, {
    void Function(articles_pb.Article updated)? onUpdated,
  }) async {
    final intId = int.parse(id);

    // Check local cache
    final cachedDetail = await _db.getDetail(intId);
    final cachedPreview = await _db.getPreview(intId);
    articles_pb.Article? cachedArticle;
    if (cachedDetail != null && cachedPreview != null) {
      cachedArticle = detailRowToProto(cachedPreview, cachedDetail);
    }

    // If online, fetch from server in background and update cache (and UI via onUpdated) when it arrives
    final fetchFuture = _isOnline ? _fetchAndCacheDetail(id, intId) : null;
    if (_isOnline && onUpdated != null) {
      fetchFuture!
          .then((article) {
            if (article != null) onUpdated(article);
          })
          .catchError((_) {});
    }

    // We have started the fetch, if the article is present in the cache return it immediately and we will call onUpdate once we recieve the fresh one
    if (cachedArticle != null) return cachedArticle;

    // Not cached + offline: return null (caller shows error)
    if (!_isOnline) return null;

    // Not cached + online: wait for fetch
    return fetchFuture;
  }

  Future<articles_pb.Article?> _fetchAndCacheDetail(
    String id,
    int intId,
  ) async {
    try {
      final article = await _remote.getArticle(id);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Cache preview
      await _db.upsertPreview(articleToPreviewCompanion(article, 0, now));

      // Cache detail
      Uint8List? phonemizerBlob;
      String processedHtml = article.extractedHtml;
      if (article.phonemizerData.isNotEmpty) {
        // Wrap repeated PhonemizerData in a container message for serialization
        final container = articles_pb.Article()
          ..phonemizerData.addAll(article.phonemizerData);
        // We serialize only the phonemizerData field - extract the bytes from the full message
        // and store them. On read, we deserialize the same way.
        phonemizerBlob = Uint8List.fromList(container.writeToBuffer());

        // Pre-compute sentence-annotated HTML for highlighting during TTS playback
        final sentenceTexts = buildSentenceTexts(
          protoToChunks(article.phonemizerData),
        );
        processedHtml = injectSentenceSpans(
          article.extractedHtml,
          sentenceTexts,
        );
      }

      await _db.upsertDetail(
        ArticleDetailsCompanion(
          id: Value(intId),
          extractedHtml: Value(article.extractedHtml),
          processedHtml: Value(processedHtml),
          pureText: Value(article.pureText),
          phonemizerBlob: Value(phonemizerBlob),
          cachedAt: Value(now),
        ),
      );

      // Return with processed HTML so the UI gets sentence spans immediately
      article.extractedHtml = processedHtml;
      return article;
    } catch (_) {
      return null;
    }
  }

  Future<ParseArticleResult> parseArticle(String url) async {
    if (_isOnline) {
      await _remote.parseArticle(url);
      return ParseArticleResult(queued: false);
    }

    // Queue for later
    await _db.insertPendingOp(
      PendingOperationsCompanion(
        type: const Value(opParseArticle),
        payload: Value(jsonEncode({"url": url})),
        createdAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    return ParseArticleResult(queued: true);
  }

  /// Fire-and-forget save of article progress.
  /// Always updates local DB; also syncs to server when online.
  void saveArticleProgress({
    required String articleId,
    int playerPositionMs = 0,
    double scrollPosition = 0,
    double playbackSpeed = 0,
  }) {
    final intId = int.tryParse(articleId);
    if (intId != null) {
      _db
          .updateProgress(intId, playerPositionMs, scrollPosition)
          .catchError((_) {});
    }
    if (!_isOnline) return;
    _remote
        .saveArticleProgress(
          articleId: articleId,
          playerPositionMs: playerPositionMs,
          scrollPosition: scrollPosition,
          playbackSpeed: playbackSpeed,
        )
        .catchError((_) {});
  }

  // deleteArticle with distributed transaction if online
  // or optimistic local delete if offline
  Future<void> deleteArticle(String id) async {
    final intId = int.parse(id);

    // Optimistic local delete
    final preview = await _db.getPreview(intId);
    final detail = await _db.getDetail(intId);
    await _db.deletePreview(intId);

    if (_isOnline) {
      try {
        await _remote.deleteArticle(id);
      } catch (e) {
        // Restore on failure
        if (preview != null) {
          await _db.upsertPreview(previewRowToCompanion(preview));
        }
        if (detail != null) {
          await _db.upsertDetail(detailRowToCompanion(detail));
        }
        rethrow;
      }
    } else {
      // Queue for later
      await _db.insertPendingOp(
        PendingOperationsCompanion(
          type: const Value(opDeleteArticle),
          payload: Value(jsonEncode({"article_id": id})),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
  }

  /// Moves an article between lists and/or toggles its favorite flag. Updates
  /// the local cache optimistically, then syncs to the server (or queues the
  /// op when offline). Returns the updated preview for the caller to broadcast,
  /// or null if the article isn't cached
  Future<articles_pb.ArticlePreview?> setArticleState(
    String id, {
    ArticleListState? listState,
    bool? isFavorite,
  }) async {
    final intId = int.parse(id);

    final previous = await _db.getPreview(intId);
    if (previous == null) return null;

    // Optimistic local update
    await _db.updateArticleFlags(
      intId,
      listState: listState?.db,
      isFavorite: isFavorite,
    );
    final updated = await _db.getPreview(intId);
    final updatedProto = updated != null ? previewRowToProto(updated) : null;

    if (_isOnline) {
      try {
        await _remote.setArticleState(
          id,
          listState: listState,
          isFavorite: isFavorite,
        );
      } catch (e) {
        // Restore previous flags on failure
        await _db.upsertPreview(previewRowToCompanion(previous));
        rethrow;
      }
    } else {
      // Queue for later
      await _db.insertPendingOp(
        PendingOperationsCompanion(
          type: const Value(opSetArticleState),
          payload: Value(
            jsonEncode({
              "article_id": id,
              if (listState != null) "list_state": listState.db,
              if (isFavorite != null) "is_favorite": isFavorite,
            }),
          ),
          createdAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
    }
    return updatedProto;
  }
}

// Provider declaration for repository
final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  final db = ref.read(appDatabaseProvider);
  final remote = ref.read(articlesServiceProvider);
  return ArticleRepository(db, remote, ref);
});
// -- Conversion helpers --

articles_pb.ArticlePreview previewRowToProto(ArticlePreview row) {
  return articles_pb.ArticlePreview(
    id: Int64(row.id),
    status: row.status,
    title: row.title,
    author: row.author,
    date: row.date,
    url: row.url,
    categories: (jsonDecode(row.categories) as List).cast<String>(),
    description: row.description,
    image: row.imageUrl,
    playerPositionMs: Int64(row.playerPositionMs),
    scrollPosition: row.scrollPosition,
    listState: ArticleListState.fromDb(row.listState).proto,
    isFavorite: row.isFavorite,
  );
}

ArticlePreviewsCompanion previewProtoToCompanion(
  articles_pb.ArticlePreview proto,
  int sortOrder,
  int cachedAt,
) {
  return ArticlePreviewsCompanion(
    id: Value(proto.id.toInt()),
    status: Value(proto.status),
    title: Value(proto.title),
    author: Value(proto.author),
    date: Value(proto.date),
    url: Value(proto.url),
    categories: Value(jsonEncode(proto.categories)),
    description: Value(proto.description),
    imageUrl: Value(proto.image),
    sortOrder: Value(sortOrder),
    cachedAt: Value(cachedAt),
    playerPositionMs: Value(proto.playerPositionMs.toInt()),
    scrollPosition: Value(proto.scrollPosition),
    listState: Value(ArticleListState.fromProto(proto.listState).db),
    isFavorite: Value(proto.isFavorite),
  );
}

ArticlePreviewsCompanion articleToPreviewCompanion(
  articles_pb.Article article,
  int sortOrder,
  int cachedAt,
) {
  return ArticlePreviewsCompanion(
    id: Value(article.id.toInt()),
    status: Value(article.status),
    title: Value(article.title),
    author: Value(article.author),
    date: Value(article.date),
    url: Value(article.url),
    categories: Value(jsonEncode(article.categories)),
    description: Value(article.description),
    imageUrl: Value(article.image),
    sortOrder: Value(sortOrder),
    cachedAt: Value(cachedAt),
    playerPositionMs: Value(article.playerPositionMs.toInt()),
    scrollPosition: Value(article.scrollPosition),
    listState: Value(ArticleListState.fromProto(article.listState).db),
    isFavorite: Value(article.isFavorite),
  );
}

ArticlePreviewsCompanion previewRowToCompanion(ArticlePreview row) {
  return ArticlePreviewsCompanion(
    id: Value(row.id),
    status: Value(row.status),
    title: Value(row.title),
    author: Value(row.author),
    date: Value(row.date),
    url: Value(row.url),
    categories: Value(row.categories),
    description: Value(row.description),
    imageUrl: Value(row.imageUrl),
    sortOrder: Value(row.sortOrder),
    cachedAt: Value(row.cachedAt),
    playerPositionMs: Value(row.playerPositionMs),
    scrollPosition: Value(row.scrollPosition),
    listState: Value(row.listState),
    isFavorite: Value(row.isFavorite),
  );
}

ArticleDetailsCompanion detailRowToCompanion(ArticleDetail row) {
  return ArticleDetailsCompanion(
    id: Value(row.id),
    extractedHtml: Value(row.extractedHtml),
    processedHtml: Value(row.processedHtml),
    pureText: Value(row.pureText),
    phonemizerBlob: Value(row.phonemizerBlob),
    cachedAt: Value(row.cachedAt),
  );
}

articles_pb.Article detailRowToProto(
  ArticlePreview preview,
  ArticleDetail detail,
) {
  List<articles_pb.PhonemizerData> phonemizerData = [];
  if (detail.phonemizerBlob != null) {
    try {
      final container = articles_pb.Article.fromBuffer(detail.phonemizerBlob!);
      phonemizerData = container.phonemizerData;
    } catch (e) {
      print("Failed to decode phonemizer data for article ${preview.id}: $e");
    }
  }

  // Use processedHtml (with sentence spans) if available, fall back to raw
  final html = detail.processedHtml.isNotEmpty
      ? detail.processedHtml
      : detail.extractedHtml;

  return articles_pb.Article(
    id: Int64(preview.id),
    status: preview.status,
    title: preview.title,
    author: preview.author,
    date: preview.date,
    url: preview.url,
    categories: (jsonDecode(preview.categories) as List).cast<String>(),
    description: preview.description,
    image: preview.imageUrl,
    extractedHtml: html,
    pureText: detail.pureText,
    phonemizerData: phonemizerData,
    playerPositionMs: Int64(preview.playerPositionMs),
    scrollPosition: preview.scrollPosition,
    listState: ArticleListState.fromDb(preview.listState).proto,
    isFavorite: preview.isFavorite,
  );
}
