import "dart:io";
import "dart:typed_data";

import "package:flutter_test/flutter_test.dart";
import "package:path_provider_platform_interface/path_provider_platform_interface.dart";
import "package:plugin_platform_interface/plugin_platform_interface.dart";
import "package:readintent_flutter/features/tts/audio_cache.dart";

class FakePathProvider extends Fake with MockPlatformInterfaceMixin implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProvider(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

void main() {
  late Directory tempDir;
  late AudioCache cache;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync("audio_cache_test_");
    PathProviderPlatform.instance = FakePathProvider(tempDir);
    cache = AudioCache();
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group("AudioCache", () {
    test("cacheKey is deterministic", () {
      final key1 = cache.cacheKey(articleId: "1", articleText: "Hello world", voice: "af", speed: 1.0);
      final key2 = cache.cacheKey(articleId: "1", articleText: "Hello world", voice: "af", speed: 1.0);
      expect(key1, key2);
    });

    test("cacheKey differs for different text", () {
      final key1 = cache.cacheKey(articleId: "1", articleText: "Hello", voice: "af", speed: 1.0);
      final key2 = cache.cacheKey(articleId: "1", articleText: "Hello!", voice: "af", speed: 1.0);
      expect(key1, isNot(key2));
    });

    test("cacheKey differs for different voice", () {
      final key1 = cache.cacheKey(articleId: "1", articleText: "Hello", voice: "af", speed: 1.0);
      final key2 = cache.cacheKey(articleId: "1", articleText: "Hello", voice: "bm", speed: 1.0);
      expect(key1, isNot(key2));
    });

    test("cacheKey differs for different speed", () {
      final key1 = cache.cacheKey(articleId: "1", articleText: "Hello", voice: "af", speed: 1.0);
      final key2 = cache.cacheKey(articleId: "1", articleText: "Hello", voice: "af", speed: 1.5);
      expect(key1, isNot(key2));
    });

    test("load returns null for missing key", () async {
      final result = await cache.load("nonexistent");
      expect(result, isNull);
    });

    test("save and load roundtrip", () async {
      final data = Uint8List.fromList([1, 2, 3, 4]);
      final key = cache.cacheKey(articleId: "1", articleText: "Test article", voice: "af", speed: 1.0);

      await cache.save(key, data);
      final loaded = await cache.load(key);

      expect(loaded, isNotNull);
      expect(await loaded!.readAsBytes(), data);
    });

    test("incremental save overwrites previous snapshot", () async {
      final key = cache.cacheKey(articleId: "1", articleText: "Test article", voice: "af", speed: 1.0);

      await cache.save(key, Uint8List.fromList([1, 2, 3]));
      await cache.save(key, Uint8List.fromList([1, 2, 3, 4, 5]));

      final loaded = await cache.load(key);
      expect(await loaded!.readAsBytes(), Uint8List.fromList([1, 2, 3, 4, 5]));
    });

    test("pathForKey returns consistent path", () async {
      final key = cache.cacheKey(articleId: "1", articleText: "Test article", voice: "af", speed: 1.0);
      final path1 = await cache.pathForKey(key);
      final path2 = await cache.pathForKey(key);
      expect(path1, path2);
      expect(path1, endsWith("$key.wav"));
    });
  });
}
