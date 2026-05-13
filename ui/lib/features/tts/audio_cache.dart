import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:fnv/fnv.dart";
import "package:path_provider/path_provider.dart";

class AudioCache {
  // We will store generated audio files up-to 500Mb in total.
  // If we exceed this, we will evict the least recently accessed files until we are under the limit again.
  static const int _maxCacheBytes = 500 * 1024 * 1024; // 500MB
  Directory? _cacheDir;

  // Make sure we have the directory available for caching
  Future<Directory> _getDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationSupportDirectory();
    _cacheDir = Directory("${base.path}/tts_cache");
    if (!await _cacheDir!.exists()) {
      await _cacheDir!.create(recursive: true);
    }
    return _cacheDir!;
  }

  /// Cache key from article ID, FNV1-32 hash of text content, voice, and speed.
  /// Including content hash ensures cache invalidation when article text changes.
  String cacheKey({
    required String articleId,
    required String articleText,
    required String voice,
    required double speed,
  }) {
    final hash = fnv1_32(utf8.encode(articleText));
    return "${articleId}_${hash.toRadixString(16)}_${voice}_${speed.toStringAsFixed(1)}";
  }

  /// Load cached audio file for a key, or return null if not found.
  Future<File?> load(String key) async {
    final dir = await _getDir();
    final file = File("${dir.path}/$key.mp3");
    if (await file.exists()) {
      // Update last accessed time for LRU eviction
      await file.setLastAccessed(DateTime.now());
      return file;
    }
    return null;
  }

  /// Get the file path for a key
  Future<String> pathForKey(String key) async {
    final dir = await _getDir();
    return "${dir.path}/$key.mp3";
  }

  /// Save bytes to cache.
  Future<File> save(String key, Uint8List bytes) async {
    final dir = await _getDir();
    final file = File("${dir.path}/$key.mp3");
    await file.writeAsBytes(bytes);
    await _evictIfNeeded();
    return file;
  }

  /// Move/copy an existing file into the cache directory.
  Future<File> saveFile(String key, File source) async {
    final dir = await _getDir();
    final dest = File("${dir.path}/$key.mp3");
    try {
      // Try rename (move) first — fast, no copy needed
      await source.rename(dest.path);
    } on FileSystemException {
      // Cross-device move: fall back to copy + delete
      await source.copy(dest.path);
      await source.delete();
    }
    await _evictIfNeeded();
    return dest;
  }

  /// Evict least recently accessed files until total cache size is under the limit.
  Future<void> _evictIfNeeded() async {
    final dir = await _getDir();
    // Get all cached files and their total size
    final files = dir.listSync().whereType<File>().where((f) => f.path.endsWith(".mp3")).toList();
    // Run reducer to sum file sizes
    int total = files.fold(0, (sum, f) => sum + f.lengthSync());
    if (total <= _maxCacheBytes) return;

    files.sort((a, b) => a.statSync().accessed.compareTo(b.statSync().accessed));

    for (final f in files) {
      if (total <= _maxCacheBytes) break;
      total -= f.lengthSync();
      await f.delete();
    }
  }
}
