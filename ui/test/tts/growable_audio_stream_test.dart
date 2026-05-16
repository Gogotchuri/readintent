import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:readintent_flutter/features/tts/growing_audio_file.dart";

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync("growing_audio_test_");
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  String tempPath() => "${tempDir.path}/test.mp3";

  group("GrowingAudioFile", () {
    test("starts with zero buffered duration", () {
      final file = GrowingAudioFile(filePath: tempPath());
      expect(file.bufferedDuration, Duration.zero);
      expect(file.lastEncodedChunkIndex, -1);
    });

    test("bufferedDuration increases after addChunk", () async {
      final file = GrowingAudioFile(filePath: tempPath());
      // 24000 samples = 1 second at 24kHz
      await file.addChunk(Float32List(24000), 0);
      expect(file.bufferedDuration.inMilliseconds, 1000);
      expect(file.lastEncodedChunkIndex, 0);
      await file.dispose();
    });

    test("multiple addChunk calls accumulate duration", () async {
      final file = GrowingAudioFile(filePath: tempPath());
      await file.addChunk(Float32List(12000), 0); // 0.5s
      await file.addChunk(Float32List(12000), 1); // 0.5s
      expect(file.bufferedDuration.inMilliseconds, 1000);
      expect(file.lastEncodedChunkIndex, 1);
      await file.dispose();
    });

    test("addChunk writes MP3 data to file", () async {
      final path = tempPath();
      final file = GrowingAudioFile(filePath: path);
      await file.addChunk(Float32List(24000), 0);

      final mp3File = File(path);
      expect(mp3File.existsSync(), true);
      final bytes = mp3File.readAsBytesSync();
      expect(bytes.isNotEmpty, true);
      // MP3 frame sync word
      expect(bytes[0], 0xFF);
      expect(bytes[1] & 0xE0, 0xE0);

      await file.dispose();
    });

    test("addChunk writes .meta file", () async {
      final path = tempPath();
      final file = GrowingAudioFile(filePath: path);
      await file.addChunk(Float32List(24000), 3);

      final metaFile = File("$path.meta");
      expect(metaFile.existsSync(), true);
      final meta = jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      expect(meta["lastChunkIndex"], 3);
      expect(meta["pcmLength"], 24000 * 2);

      await file.dispose();
    });

    test("lastEncodedChunkIndex tracks chunk progress", () async {
      final file = GrowingAudioFile(filePath: tempPath());
      expect(file.lastEncodedChunkIndex, -1);

      await file.addChunk(Float32List(12000), 0);
      expect(file.lastEncodedChunkIndex, 0);

      await file.addChunk(Float32List(12000), 1);
      expect(file.lastEncodedChunkIndex, 1);

      await file.addChunk(Float32List(12000), 2);
      expect(file.lastEncodedChunkIndex, 2);

      await file.dispose();
    });

    test("finalize flushes encoder and deletes meta", () async {
      final path = tempPath();
      final file = GrowingAudioFile(filePath: path);
      await file.addChunk(Float32List(24000), 0);

      final metaFile = File("$path.meta");
      expect(metaFile.existsSync(), true);

      await file.finalize();

      // MP3 file should still exist
      expect(File(path).existsSync(), true);
      // Meta file should be deleted
      expect(metaFile.existsSync(), false);

      await file.dispose();
    });

    test("tryResume returns null when no meta file", () {
      final result = GrowingAudioFile.tryResume(tempPath());
      expect(result, isNull);
    });

    test("tryResume restores state from meta file", () async {
      final path = tempPath();
      // Create an audio file with some chunks
      final file = GrowingAudioFile(filePath: path);
      await file.addChunk(Float32List(24000), 0);
      await file.addChunk(Float32List(12000), 1);
      await file.dispose();

      // Now try to resume
      final resumed = GrowingAudioFile.tryResume(path);
      expect(resumed, isNotNull);
      expect(resumed!.lastEncodedChunkIndex, 1);
      expect(resumed.bufferedDuration.inMilliseconds, 1500); // 1s + 0.5s
      expect(resumed.filePath, path);

      await resumed.dispose();
    });

    test("tryResume returns null when meta exists but mp3 missing", () async {
      final path = tempPath();
      // Write only the meta file, no mp3
      File("$path.meta").writeAsStringSync(jsonEncode({"lastChunkIndex": 2, "pcmLength": 48000}));

      final result = GrowingAudioFile.tryResume(path);
      expect(result, isNull);
    });

    test("dispose() closes bufferedDurationStream", () async {
      final file = GrowingAudioFile(filePath: tempPath());
      await file.addChunk(Float32List(12000), 0);

      await file.dispose();

      bool streamDone = false;
      file.bufferedDurationStream.listen((_) {}, onDone: () => streamDone = true);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(streamDone, true);
    });

    test("large sample accumulation (10s / 240k samples)", () async {
      final file = GrowingAudioFile(filePath: tempPath());
      // 240000 samples = 10 seconds at 24kHz
      await file.addChunk(Float32List(240000), 0);
      expect(file.bufferedDuration.inSeconds, 10);
      expect(file.lastEncodedChunkIndex, 0);

      final mp3File = File(tempPath());
      expect(mp3File.existsSync(), true);
      expect(mp3File.lengthSync(), greaterThan(0));

      await file.dispose();
    });

    test("tryResume returns null on corrupt .meta JSON", () {
      final path = tempPath();
      // Write corrupt JSON
      File("$path.meta").writeAsStringSync("not valid json {{{");
      File(path).writeAsBytesSync(Uint8List.fromList([0xFF, 0xFB, 0x90, 0x00]));

      final result = GrowingAudioFile.tryResume(path);
      expect(result, isNull);
    });

    test("bufferedDurationStream emits updates", () async {
      final file = GrowingAudioFile(filePath: tempPath());

      final durations = <Duration>[];
      final sub = file.bufferedDurationStream.listen(durations.add);

      await file.addChunk(Float32List(12000), 0); // 0.5s
      // Give stream time to deliver before adding next chunk
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await file.addChunk(Float32List(12000), 1); // 1.0s total
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(durations.length, 2);
      expect(durations[0].inMilliseconds, 500);
      expect(durations[1].inMilliseconds, 1000);

      await sub.cancel();
      await file.dispose();
    });
  });
}
