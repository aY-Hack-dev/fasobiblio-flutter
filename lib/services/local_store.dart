import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  static const favoritesKey = 'fasobiblio.flutter.favorites';
  static const laterKey = 'fasobiblio.flutter.later';

  Future<Set<String>> load(String key) async => (await SharedPreferences.getInstance()).getStringList(key)?.toSet() ?? <String>{};
  Future<void> save(String key, Set<String> values) async => (await SharedPreferences.getInstance()).setStringList(key, values.toList());
}
