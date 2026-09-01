import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

class LocalStore {
  static const favoritesKey = 'fasobiblio.flutter.favorites';
  static const laterKey = 'fasobiblio.flutter.later';
  static const catalogKey = 'fasobiblio.flutter.catalog';
  static const lastSyncKey = 'fasobiblio.flutter.lastSync';

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
}
