import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:readintent_flutter/models/user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_storage.g.dart';

/// SessionStorage is a simple wrapper around FlutterSecureStorage to manage session tokens and user data
class SessionStorage {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'session_token';
  static const _userKey = 'user_data';
  // _cache is used to store the session token and user data in memory for faster access, avoiding slight overhead of secure storage reads on every request
  String? _cachedToken;

  /// getToken retrieves the session token from secure storage, returns null if not found
  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: _tokenKey);
    return _cachedToken;
  }

  /// saveToken saves the session token to secure storage
  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: _tokenKey, value: token);
  }

  /// getUser retrieves the user data from secure storage, returns null if not found
  Future<User?> getUser() async {
    final userData = await _storage.read(key: _userKey);
    if (userData == null) return null;
    final userMap = jsonDecode(userData) as Map<String, dynamic>;
    return User.fromJson(userMap);
  }

  /// saveUser saves the user data to secure storage
  Future<void> saveUser(User user) async {
    await _storage.write(key: _userKey, value: jsonEncode(user.toJson()));
  }

  /// clearSession clears the session token and user data from secure storage
  Future<void> clearSession() async {
    _cachedToken = null;
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}

/// sessionStorage is a provider that exposes an instance of SessionStorage for dependency injection
@Riverpod(keepAlive: true)
SessionStorage sessionStorage(_) {
  return SessionStorage();
}
