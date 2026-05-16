import "dart:io";
import "dart:typed_data";

import "package:fixnum/fixnum.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:just_audio/just_audio.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";

import "package:readintent_flutter/features/articles/providers/article_player_provider.dart";
import "package:readintent_flutter/features/tts/audio_handler.dart";
import "package:readintent_flutter/features/tts/pipeline.dart";
import "package:readintent_flutter/proto/articles/v1/articles_service.pb.dart" as pb;

import "../../helpers/fakes.dart";

pb.Article _makeArticle(int chunkCount, {int tokensPerChunk = 100}) {
  final article = pb.Article(
    id: Int64(1),
    title: "Test Article",
    author: "Author",
    pureText: "Some test text for the article e2e",
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

Future<void> pumpEvents() => Future<void>.delayed(const Duration(milliseconds: 50));

/// Creates container with listener to keep the autoDispose provider alive.
ProviderContainer _makeContainer(FakeAudioHandler handler, PipelineFactory factory) {
  final c = createTestContainer(handler: handler, pipelineFactory: factory);
  c.listen(articlePlayerProvider("1"), (_, __) {});
  return c;
}

void main() {
  late Directory tempDir;
  late FakeAudioHandler handler;
  late ProviderContainer container;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync("article_player_e2e_");
    PathProviderPlatform.instance = FakePathProvider(tempDir);
    handler = FakeAudioHandler();
  });

  tearDown(() async {
    container.dispose();
    await handler.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group("E2E Scenario 1: Full Playback Lifecycle", () {
    test("play → generation → buffer ready → play → pause → resume → complete → dispose", () async {
      final factory = fakePipelineFactory(defaultAudioProducer);
      container = _makeContainer(handler, factory);

      final notifier = container.read(articlePlayerProvider("1").notifier);
      final article = _makeArticle(5, tokensPerChunk: 100);

      // Initial state
      var state = container.read(articlePlayerProvider("1"));
      expect(state.position, Duration.zero);
      expect(state.isPlaying, false);
      expect(state.isLoading, false);

      // Play
      await notifier.play(article: article);
      await pumpEvents();

      // After generation completes
      state = container.read(articlePlayerProvider("1"));
      expect(state.ttsComplete, true);
      expect(state.bufferedDuration.inMilliseconds, greaterThan(0));
      expect(state.estimatedDuration, isNotNull);
      expect(handler.calls, contains("setSource"));
      expect(handler.calls, contains("play"));

      // Simulate position update
      handler.emitPosition(const Duration(seconds: 1));
      await pumpEvents();
      state = container.read(articlePlayerProvider("1"));
      expect(state.position, const Duration(seconds: 1));

      // Pause
      await notifier.pause();
      handler.simulateProcessingState(ProcessingState.ready);
      await pumpEvents();
      state = container.read(articlePlayerProvider("1"));
      expect(state.isPlaying, false);

      // Resume
      await notifier.resume();
      handler.simulateProcessingState(ProcessingState.ready);
      await pumpEvents();
      state = container.read(articlePlayerProvider("1"));
      expect(state.isPlaying, true);

      // Verify MP3 file on disk
      expect(handler.lastSourcePath, isNotNull);
      final mp3File = File(handler.lastSourcePath!);
      expect(mp3File.existsSync(), true);
      expect(mp3File.lengthSync(), greaterThan(0));
      expect(File("${handler.lastSourcePath!}.meta").existsSync(), false);

      // Dispose
      container.dispose();
    });
  });

  group("E2E Scenario 2: Buffer Stall + Recovery", () {
    test("ProcessingState.completed during generation → stall → recovery", () async {
      final factory = fakePipelineFactory(defaultAudioProducer);
      container = _makeContainer(handler, factory);

      final notifier = container.read(articlePlayerProvider("1").notifier);
      final article = _makeArticle(3);

      await notifier.play(article: article);
      await pumpEvents();

      var state = container.read(articlePlayerProvider("1"));
      expect(state.ttsComplete, true);

      // When ProcessingState.completed arrives with ttsComplete=true, track finishes
      handler.simulateProcessingState(ProcessingState.completed);
      await pumpEvents();

      state = container.read(articlePlayerProvider("1"));
      expect(state.isPlaying, false);
    });
  });

  group("E2E Scenario 3: Cached Playback", () {
    test("pre-generated file → plays from cache, no re-generation", () async {
      final factory = fakePipelineFactory(defaultAudioProducer);
      container = _makeContainer(handler, factory);

      final article = _makeArticle(2);

      // First play: generates audio
      final notifier1 = container.read(articlePlayerProvider("1").notifier);
      await notifier1.play(article: article);
      await pumpEvents();

      var state = container.read(articlePlayerProvider("1"));
      expect(state.ttsComplete, true);

      // Dispose and recreate to simulate new session
      container.dispose();
      handler = FakeAudioHandler();
      handler.sourceDuration = const Duration(minutes: 2);

      int inferenceCount = 0;
      final countingFactory = fakePipelineFactory((chunk) {
        inferenceCount++;
        return defaultAudioProducer(chunk);
      });
      container = _makeContainer(handler, countingFactory);

      final notifier2 = container.read(articlePlayerProvider("1").notifier);
      await notifier2.play(article: article);
      await pumpEvents();

      state = container.read(articlePlayerProvider("1"));
      expect(state.ttsComplete, true);
      // No inference should have been called — played from cache
      expect(inferenceCount, 0);
    });
  });

  group("E2E Scenario 4: Error During Generation", () {
    test("pipeline throws on chunk 2 → error state set", () async {
      int callCount = 0;
      final errorFactory = fakePipelineFactory((chunk) {
        callCount++;
        if (callCount >= 2) throw Exception("Chunk 2 failed");
        return defaultAudioProducer(chunk);
      });

      container = _makeContainer(handler, errorFactory);
      final notifier = container.read(articlePlayerProvider("1").notifier);

      await notifier.play(article: _makeArticle(3));
      await pumpEvents();

      final state = container.read(articlePlayerProvider("1"));
      expect(state.error, isNotNull);
      expect(state.error, contains("Chunk 2 failed"));
      expect(state.isLoading, false);
    });
  });
}
