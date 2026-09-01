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
  bool offline = false;
  DateTime? lastSync;
  String? error;

  Future<void> load({bool refresh = false}) async {
    refresh ? refreshing = true : loading = true;
    error = null;
    notifyListeners();
    final local = await Future.wait([store.loadCatalog(), store.load(LocalStore.favoritesKey), store.load(LocalStore.laterKey), store.lastSync()]);
    books = local[0] as List<Book>;
    favorites = local[1] as Set<String>;
    later = local[2] as Set<String>;
    lastSync = local[3] as DateTime?;
    session ??= UserSession.offlineGuest();
    loading = false;
    refreshing = true;
    notifyListeners();

    try {
      final values = await Future.wait([api.ensureSession(), api.catalog(), api.plans().catchError((_) => <dynamic>[])]);
      session = values[0] as UserSession;
      books = values[1] as List<Book>;
      offers = values[2] as List<dynamic>;
      await store.saveCatalog(books);
      lastSync = DateTime.now();
      offline = false;
    } catch (e) {
      offline = true;
      error = books.isEmpty ? 'Mode hors connexion : le catalogue sera disponible après une première synchronisation.' : null;
    }
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
