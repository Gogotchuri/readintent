import "package:readintent_flutter/features/articles/repository/article_repository.dart";
import "package:readintent_flutter/features/settings/providers/app_settings_provider.dart";
import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/audio_generator.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";

part "article_prefetch_service.g.dart";

/// Silently prefetches article detail and caches them in the background for offline playback
@Riverpod(keepAlive: true)
class ArticlePrefetchService extends _$ArticlePrefetchService {
  final Set<String> _seen = {};
  final List<String> _queue = [];
  bool _running = false;

  @override
  void build() {}

  void enqueue(String id) {
    if (_seen.contains(id)) return;
    _seen.add(id);
    _queue.add(id);
    if (!_running) _processNext();
  }

  void _processNext() {
    if (_queue.isEmpty) {
      _running = false;
      return;
    }
    _running = true;
    final id = _queue.removeAt(0);
    _prefetchOne(id).whenComplete(_processNext);
  }

  Future<void> _prefetchOne(String id) async {
    try {
      final repository = ref.read(articleRepositoryProvider);
      await repository.getArticle(id);
    } catch (e) {
      print("[prefetch] $id — error: $e");
    }
  }
}
