import "dart:convert";
import "package:riverpod/riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

final playerPersistenceProvider = Provider<PlayerPersistence>((ref) => PlayerPersistence());

class PlayerPersistence {
  static const _key = "last_played_article";

  Future<void> save({
    required String articleId,
    required String? articleTitle,
    required String? articleAuthor,
    required String? articleImageUrl,
    required int positionMs,
    required int? estimatedDurationMs,
    required bool ttsComplete,
    required bool syncEnabled,
    required double playbackSpeed,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(
      _key,
      jsonEncode({
        "articleId": articleId,
        "articleTitle": articleTitle,
        "articleAuthor": articleAuthor,
        "articleImageUrl": articleImageUrl,
        "positionMs": positionMs,
        "estimatedDurationMs": estimatedDurationMs,
        "ttsComplete": ttsComplete,
        "syncEnabled": syncEnabled,
        "playbackSpeed": playbackSpeed,
        "timestamp": DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return null;
    final data = jsonDecode(json) as Map<String, dynamic>;

    // Expire after 7 days
    const oneWeekMs = 7 * 24 * 60 * 60 * 1000;
    final timestamp = data["timestamp"] as int? ?? 0;
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    if (age > oneWeekMs) {
      await clear();
      return null;
    }
    return data;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_key);
  }
}
