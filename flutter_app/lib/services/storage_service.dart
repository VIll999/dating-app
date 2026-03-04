import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/config/app_config.dart';
import 'package:dating_app/models/user.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // JWT Token
  Future<void> saveToken(String token) async {
    await prefs.setString(AppConfig.tokenKey, token);
  }

  String? getToken() {
    return prefs.getString(AppConfig.tokenKey);
  }

  Future<void> removeToken() async {
    await prefs.remove(AppConfig.tokenKey);
  }

  bool get hasToken => getToken() != null;

  // User ID
  Future<void> saveUserId(String userId) async {
    await prefs.setString(AppConfig.userIdKey, userId);
  }

  String? getUserId() {
    return prefs.getString(AppConfig.userIdKey);
  }

  // User Data
  Future<void> saveUser(User user) async {
    final jsonString = jsonEncode(user.toJson());
    await prefs.setString(AppConfig.userDataKey, jsonString);
  }

  User? getUser() {
    final jsonString = prefs.getString(AppConfig.userDataKey);
    if (jsonString == null) return null;
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return User.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // Clear all data (logout)
  Future<void> clearAll() async {
    await prefs.remove(AppConfig.tokenKey);
    await prefs.remove(AppConfig.userIdKey);
    await prefs.remove(AppConfig.userDataKey);
  }
}
