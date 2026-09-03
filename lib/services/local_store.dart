import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

class LocalStore {
  static const favoritesKey = 'fasobiblio.flutter.favorites';
  static const laterKey = 'fasobiblio.flutter.later';
  static const catalogKey = 'fasobiblio.flutter.catalog';
  static const lastSyncKey = 'fasobiblio.flutter.lastSync';
  static const accountAccessKey = 'fasobiblio.flutter.accountAccess';
  static const darkModeKey = 'fasobiblio.flutter.darkMode';
  static const notificationsKey = 'fasobiblio.flutter.notifications';
  static const notificationReadsKey = 'fasobiblio.flutter.notificationReads';
  static const welcomeSeenKey = 'fasobiblio.flutter.welcomeSeen';
  static const readingStateKey = 'fasobiblio.flutter.readingState';

  Future<Set<String>> load(String key) async => (await SharedPreferences.getInstance()).getStringList(key)?.toSet() ?? <String>{};
  Future<void> save(String key, Set<String> values) async => (await SharedPreferences.getInstance()).setStringList(key, values.toList());

  Future<List<Book>> loadCatalog() async {
    final raw = (await SharedPreferences.getInstance()).getString(catalogKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map>().map((item) {
        final value = Map<String, dynamic>.from(item);
        return Book.fromJson('${value['id'] ?? ''}', value);
      }).where((book) => book.id.isNotEmpty).toList();
    } catch (_) { return []; }
  }

  Future<void> saveCatalog(List<Book> books) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(catalogKey, jsonEncode(books.map((book) => book.toJson()).toList()));
    await prefs.setInt(lastSyncKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> lastSync() async {
    final value = (await SharedPreferences.getInstance()).getInt(lastSyncKey);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  Future<Map<String, dynamic>> loadAccountAccess() async {
    final raw = (await SharedPreferences.getInstance()).getString(accountAccessKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
    } catch (_) {
      return {};
    }
  }

  Future<void> saveAccountAccess(Map<String, dynamic>? subscription, Set<String> purchased) async {
    await (await SharedPreferences.getInstance()).setString(accountAccessKey, jsonEncode({
      'subscription': subscription,
      'purchased': purchased.toList(),
    }));
  }

  Future<void> clearAccountAccess() async => (await SharedPreferences.getInstance()).remove(accountAccessKey);

  Future<bool> loadDarkMode() async => (await SharedPreferences.getInstance()).getBool(darkModeKey) ?? false;
  Future<void> saveDarkMode(bool value) async => (await SharedPreferences.getInstance()).setBool(darkModeKey, value);

  Future<dynamic> loadJson(String key) async {
    final raw = (await SharedPreferences.getInstance()).getString(key);
    if (raw == null || raw.isEmpty) return null;
    try { return jsonDecode(raw); } catch (_) { return null; }
  }

  Future<void> saveJson(String key, Object value) async => (await SharedPreferences.getInstance()).setString(key, jsonEncode(value));

  Future<Map<String, dynamic>> loadReadingState() async {
    final value = await loadJson(readingStateKey);
    if (value is! Map) return {};
    return Map<String, dynamic>.from(value);
  }

  Future<void> saveReadingState(Map<String, dynamic> value) => saveJson(readingStateKey, value);

  Future<bool> loadWelcomeSeen() async => (await SharedPreferences.getInstance()).getBool(welcomeSeenKey) ?? false;
  Future<void> saveWelcomeSeen() async => (await SharedPreferences.getInstance()).setBool(welcomeSeenKey, true);
}
