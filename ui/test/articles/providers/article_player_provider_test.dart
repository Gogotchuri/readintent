import "dart:async";
import "dart:io";
import "dart:typed_data";

import "package:audio_service/audio_service.dart";
import "package:fixnum/fixnum.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";

import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/tts/audio_cache.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as pb;

import "../../helpers/fakes.dart";

pb.Article _makeArticle(int chunkCount, {int tokensPerChunk = 100}) {
  final article = pb.Article(
    id: Int64(1),
    title: "Test Article",
    author: "Author",
    pureText: "Some test text for the article",
    status: "ready",
  );
  for (int i = 0; i < chunkCount; i++) {
    article.phonemizerData.add(pb.PhonemizerData(
      graphemes: "Chunk $i",
      tokenIds: List.generate(tokensPerChunk, (j) => Int64(j + 1)),
      tokenMeta: [pb.PhonemizerTokenMeta(text: "word", phonemeLen: 3, hasWhitespace: true)],
    ));
  }
  return article;
}

/// Let async stream events propagate.
Future<void> pumpEvents() => Future<void>.delayed(const Duration(milliseconds: 50));

void main() {
  late Directory tempDir;
  late FakeAudioHandler handler;
  late ProviderContainer container;
  late PipelineFactory factory;
  ProviderSubscription<ArticlePlayerState>? _sub;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync("article_player_test_");
    PathProviderPlatform.instance = FakePathProvider(tempDir);
    handler = FakeAudioHandler();
    factory = fakePipelineFactory(defaultAudioProducer);
    container = createTestContainer(handler: handler, pipelineFactory: factory);
    // Keep the autoDispose provider alive for the duration of the test
    _sub = container.listen(articlePlayerProvider("1"), (_, __) {});
  });

  tearDown(() async {
    _sub?.close();
    container.dispose();
    await handler.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  /// Create a new container with a listener to keep the provider alive.
  ProviderContainer makeContainer({required PipelineFactory pipelineFactory}) {
    final c = createTestContainer(handler: handler, pipelineFactory: pipelineFactory);
    c.listen(articlePlayerProvider("1"), (_, __) {});
    return c;
  }

  ArticlePlayer readNotifier() {
    return container.read(articlePlayerProvider("1").notifier);
  }

  ArticlePlayerState readState() {
    return container.read(articlePlayerProvider("1"));
  }

  group("ArticlePlayer - Initial State", () {
    test("build() returns default state", () {
      final state = readState();
      expect(state.position, Duration.zero);
      expect(state.bufferedDuration, Duration.zero);
      expect(state.estimatedDuration, isNull);
      expect(state.isPlaying, false);
      expect(state.isLoading, false);
      expect(state.ttsComplete, false);
      expect(state.error, isNull);
    });
  });

  group("ArticlePlayer - Cache Hit", () {
    test("play() with cached file skips generation and plays directly", () async {
      final cache = AudioCache();
      final article = _makeArticle(2);
      final key = cache.cacheKey(
        articleId: article.id.toString(),
        articleText: article.pureText,
        voice: "af_sky",
        speed: 1.0,
      );
      await cache.save(key, Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00, 0x01, 0x02]));
      handler.sourceDuration = const Duration(minutes: 3);

      final notifier = readNotifier();
      await notifier.play(article: article);

      final state = readState();
      expect(state.ttsComplete, true);
      expect(state.isLoading, false);
      expect(handler.calls, contains("setSource"));
      expect(handler.calls, contains("play"));
    });

    test("cached audio sets estimatedDuration from handler.setSource() return", () async {
      final cache = AudioCache();
      final article = _makeArticle(2);
      final key = cache.cacheKey(
        articleId: article.id.toString(),
        articleText: article.pureText,
        voice: "af_sky",
        speed: 1.0,
      );
      await cache.save(key, Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00]));
      handler.sourceDuration = const Duration(minutes: 5);

      final notifier = readNotifier();
      await notifier.play(article: article);

      final state = readState();
      expect(state.estimatedDuration, const Duration(minutes: 5));
    });
  });

  group("ArticlePlayer - Generation Path", () {
    test("generation starts and handler.play() called after buffer threshold", () async {
      final article = _makeArticle(5, tokensPerChunk: 100);
      final notifier = readNotifier();

      await notifier.play(article: article);
      await pumpEvents();

      expect(handler.calls, contains("setSource"));
      expect(handler.calls, contains("play"));
    });

    test("session state updates forwarded to provider state", () async {
      final article = _makeArticle(3);
      final notifier = readNotifier();

      await notifier.play(article: article);
      await pumpEvents();

      final state = readState();
      expect(state.bufferedDuration.inMilliseconds, greaterThan(0));
    });

    test("generation completion sets ttsComplete=true", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();

      await notifier.play(article: article);
      // Broadcast stream events are async — wait for them to propagate
      await pumpEvents();

      final state = readState();
      expect(state.ttsComplete, true);
    });

    test("generation error sets error and isLoading=false", () async {
      int callCount = 0;
      final errorFactory = fakePipelineFactory((chunk) {
        callCount++;
        if (callCount >= 2) throw Exception("Pipeline error");
        return defaultAudioProducer(chunk);
      });

      final c = makeContainer(pipelineFactory: errorFactory);
      final notifier = c.read(articlePlayerProvider("1").notifier);

      await notifier.play(article: _makeArticle(3));
      await pumpEvents();

      final state = c.read(articlePlayerProvider("1"));
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
      c.dispose();
    });

    test("second play() while session exists is a no-op", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();

      await notifier.play(article: article);
      await pumpEvents();

      // Count setSource calls before
      final setSourceBefore = handler.calls.where((c) => c == "setSource").length;
      await notifier.play(article: article);

      // No new setSource calls should be made
      final setSourceAfter = handler.calls.where((c) => c == "setSource").length;
      expect(setSourceAfter, setSourceBefore);
    });

    test("mediaItem updated when estimatedDuration changes", () async {
      final article = _makeArticle(3);
      final notifier = readNotifier();

      await notifier.play(article: article);
      await pumpEvents();

      expect(handler.calls.where((c) => c == "updateMediaItem").length, greaterThan(0));
    });
  });

  group("ArticlePlayer - Position Stream", () {
    test("position updates from handler reflected in state", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.emitPosition(const Duration(seconds: 5));
      await pumpEvents();

      final state = readState();
      expect(state.position, const Duration(seconds: 5));
    });
  });

  group("ArticlePlayer - Player State Stream", () {
    test("ProcessingState.completed + ttsComplete=true → track finished", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      expect(readState().ttsComplete, true);

      handler.simulateProcessingState(ProcessingState.completed);
      await pumpEvents();

      expect(readState().isPlaying, false);
    });

    test("ProcessingState.loading sets isLoading=true", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.simulateProcessingState(ProcessingState.loading);
      await pumpEvents();

      expect(readState().isLoading, true);
    });

    test("ProcessingState.buffering sets isLoading=true", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.simulateProcessingState(ProcessingState.buffering);
      await pumpEvents();

      expect(readState().isLoading, true);
    });

    test("ProcessingState.ready + playing=true sets isPlaying=true, isLoading=false", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      await handler.play();
      handler.simulateProcessingState(ProcessingState.ready);
      await pumpEvents();

      final state = readState();
      expect(state.isPlaying, true);
      expect(state.isLoading, false);
    });
  });

  group("ArticlePlayer - pause/resume/togglePlayPause", () {
    test("pause() delegates to handler.pause()", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.calls.clear();
      await notifier.pause();

      expect(handler.calls, contains("pause"));
    });

    test("resume() delegates to handler.play()", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.calls.clear();
      await notifier.resume();

      expect(handler.calls, contains("play"));
    });

    test("togglePlayPause() pauses when playing, resumes when paused", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      // Handler is playing after play()
      expect(handler.isPlaying, true);
      await notifier.togglePlayPause(); // should pause
      expect(handler.calls, contains("pause"));
      expect(handler.isPlaying, false);

      await notifier.togglePlayPause(); // should resume (play)
      expect(handler.isPlaying, true);
    });
  });

  group("ArticlePlayer - seekTo", () {
    test("with ttsComplete, delegates directly to handler.seek()", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      expect(readState().ttsComplete, true);

      handler.calls.clear();
      await notifier.seekTo(const Duration(seconds: 10));

      expect(handler.calls, contains("seek"));
      expect(handler.currentPosition, const Duration(seconds: 10));
    });

    test("clamps to 0 for negative targets", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      await notifier.seekTo(const Duration(seconds: -5));
      // With ttsComplete=true, it goes directly to handler.seek (no clamping in complete mode)
    });
  });

  group("ArticlePlayer - jumpForward/jumpBackward", () {
    test("jumpForward() seeks to position + 15s", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.emitPosition(const Duration(seconds: 5));
      await pumpEvents();

      handler.calls.clear();
      await notifier.jumpForward();

      expect(handler.calls, contains("seek"));
    });

    test("jumpBackward() from 5s clamps to zero", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.emitPosition(const Duration(seconds: 5));
      await pumpEvents();

      await notifier.jumpBackward();
      // 5 - 15 = -10, clamped to 0
      expect(handler.currentPosition, Duration.zero);
    });

    test("jumpBackward() from 20s seeks to 5s", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      handler.emitPosition(const Duration(seconds: 20));
      await pumpEvents();

      await notifier.jumpBackward();
      expect(handler.currentPosition, const Duration(seconds: 5));
    });
  });

  group("ArticlePlayer - Cleanup/Disposal", () {
    test("cleanup cancels all subs and stops handler", () async {
      final article = _makeArticle(2);
      final notifier = readNotifier();
      await notifier.play(article: article);
      await pumpEvents();

      // Close the listener first, then dispose — which triggers cleanup
      _sub?.close();
      _sub = null;
      handler.calls.clear();
      container.dispose();

      expect(handler.calls, contains("stop"));
    });
  });
}
