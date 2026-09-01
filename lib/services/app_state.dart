import 'package:flutter/foundation.dart';
import '../models/book.dart';
import '../models/session.dart';
import 'fasobiblio_api.dart';
import 'local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.api, this.store);
  final FasobiblioApi api;
  final LocalStore store;
  List<Book> books = [];
  List<dynamic> offers = [];
  Set<String> favorites = {};
  Set<String> later = {};
  UserSession? session;
  bool loading = true;
  bool refreshing = false;
  String? error;

  Future<void> load({bool refresh = false}) async {
    refresh ? refreshing = true : loading = true;
    error = null;
    notifyListeners();
    try {
      final values = await Future.wait([api.ensureSession(), api.catalog(), store.load(LocalStore.favoritesKey), store.load(LocalStore.laterKey), api.plans().catchError((_) => <dynamic>[])]);
      session = values[0] as UserSession;
      books = values[1] as List<Book>;
      favorites = values[2] as Set<String>;
      later = values[3] as Set<String>;
      offers = values[4] as List<dynamic>;
    } catch (e) { error = e.toString().replaceFirst('Exception: ', ''); }
    loading = false;
    refreshing = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(String id) async {
    favorites.contains(id) ? favorites.remove(id) : favorites.add(id);
    notifyListeners();
    await store.save(LocalStore.favoritesKey, favorites);
  }
  Future<void> toggleLater(String id) async {
    later.contains(id) ? later.remove(id) : later.add(id);
    notifyListeners();
    await store.save(LocalStore.laterKey, later);
  }
  Future<void> login(String pseudo, String password) async { session = await api.login(pseudo, password); notifyListeners(); }
  Future<void> signup(String pseudo, String password, String phone) async { session = await api.signup(pseudo, password, phone); notifyListeners(); }
  Future<void> logout() async { session = await api.logout(); notifyListeners(); }
}
