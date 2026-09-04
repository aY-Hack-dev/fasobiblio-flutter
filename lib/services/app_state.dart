import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/book.dart';
import '../models/app_notification.dart';
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
  Map<String, dynamic>? subscription;
  Set<String> purchased = {};
  List<AppNotification> notifications = [];
  Set<String> notificationReads = {};
  String? lastOpenedBookId;
  bool loading = true;
  bool refreshing = false;
  bool offline = false;
  DateTime? lastSync;
  String? error;
  bool darkMode = false;
  bool welcomeSeen = false;
  bool _hydrated = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  int get unreadNotifications => notifications.where((item) => !notificationReads.contains(item.id)).length;

  Book? get lastOpenedBook {
    final id = lastOpenedBookId;
    if (id == null || id.isEmpty) return null;
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Future<void> startConnectivityMonitoring() async {
    final connectivity = Connectivity();
    _connectivitySubscription ??= connectivity.onConnectivityChanged.listen((results) {
      final connected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      if (!connected) {
        offline = true;
        notifyListeners();
      } else if (offline && !refreshing) {
        load(refresh: true);
      }
    });
  }

  Future<void> load({bool refresh = false}) async {
    refresh ? refreshing = true : loading = true;
    error = null;
    notifyListeners();
    if (!_hydrated) {
      final local = await Future.wait([
        store.loadCatalog(),
        store.load(LocalStore.favoritesKey),
        store.load(LocalStore.laterKey),
        store.lastSync(),
        store.loadAccountAccess(),
        store.loadDarkMode(),
        store.loadJson(LocalStore.notificationsKey),
        store.load(LocalStore.notificationReadsKey),
        store.loadWelcomeSeen(),
        store.loadJson(LocalStore.lastOpenedDocumentKey),
      ]);
      books = local[0] as List<Book>;
      favorites = local[1] as Set<String>;
      later = local[2] as Set<String>;
      lastSync = local[3] as DateTime?;
      final access = local[4] as Map<String, dynamic>;
      subscription = access['subscription'] is Map ? Map<String, dynamic>.from(access['subscription']) : null;
      purchased = (access['purchased'] is List ? access['purchased'] as List : const []).map((id) => '$id').where((id) => id.isNotEmpty).toSet();
      darkMode = local[5] as bool;
      final cachedNotifications = local[6];
      if (cachedNotifications is List) notifications = cachedNotifications.whereType<Map>().map((item) => AppNotification.fromJson('${item['id'] ?? ''}', Map<String, dynamic>.from(item))).where((item) => item.id.isNotEmpty).toList();
      notificationReads = local[7] as Set<String>;
      welcomeSeen = local[8] as bool;
      final lastOpened = local[9];
      if (lastOpened is Map) lastOpenedBookId = '${lastOpened['id'] ?? ''}'.trim();
      session ??= UserSession.offlineGuest();
      _hydrated = true;
      loading = false;
      refreshing = true;
      notifyListeners();
    }

    try {
      final values = await Future.wait([api.ensureSession(), api.catalog(), api.plans().catchError((_) => <dynamic>[]), api.notifications().catchError((_) => <AppNotification>[])]);
      session = values[0] as UserSession;
      books = values[1] as List<Book>;
      offers = values[2] as List<dynamic>;
      notifications = values[3] as List<AppNotification>;
      await _refreshAccount(notify: false);
      await store.saveCatalog(books);
      await store.saveJson(LocalStore.notificationsKey, notifications.map((item) => item.toJson()).toList());
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

  Future<void> markDocumentOpened(String id) async {
    if (id.isEmpty) return;
    lastOpenedBookId = id;
    notifyListeners();
    await store.saveJson(LocalStore.lastOpenedDocumentKey, {'id': id, 'openedAt': DateTime.now().toIso8601String()});
  }

  Future<void> toggleDarkMode(bool value) async { darkMode = value; notifyListeners(); await store.saveDarkMode(value); }
  Future<void> completeWelcome() async { welcomeSeen = true; notifyListeners(); await store.saveWelcomeSeen(); }

  Future<void> markNotificationRead(String id) async {
    notificationReads.add(id);
    notifyListeners();
    await store.save(LocalStore.notificationReadsKey, notificationReads);
    if (!offline) await api.markNotificationRead(id);
  }

  Future<void> markAllNotificationsRead() async {
    notificationReads.addAll(notifications.map((item) => item.id));
    notifyListeners();
    await store.save(LocalStore.notificationReadsKey, notificationReads);
    if (!offline) await api.markAllNotificationsRead(notifications.map((item) => item.id));
  }

  bool hasAccess(Book book) => !book.isPremium || purchased.contains(book.id) || subscription != null;

  Future<void> _refreshAccount({bool notify = true}) async {
    if (session == null || session!.anonymous) {
      subscription = null;
      purchased = {};
      if (notify) notifyListeners();
      return;
    }
    try {
      final values = await Future.wait([api.mySubscription(), api.myDocuments()]);
      subscription = values[0] as Map<String, dynamic>?;
      purchased = (values[1] as List<dynamic>)
          .whereType<Map>()
          .map((item) => '${item['docId'] ?? ''}')
          .where((id) => id.isNotEmpty)
          .toSet();
      await store.saveAccountAccess(subscription, purchased);
    } catch (_) {
      // Le catalogue et le mode hors ligne restent utilisables si le compte
      // ne peut pas être synchronisé momentanément.
    } finally {
      if (notify) notifyListeners();
    }
  }

  Future<void> refreshAccount() => _refreshAccount();
  Future<void> login(String pseudo, String password) async { session = await api.login(pseudo, password); await _refreshAccount(); }
  Future<void> signup(String pseudo, String password, String phone) async { session = await api.signup(pseudo, password, phone); await _refreshAccount(); }
  Future<void> logout() async { session = await api.logout(); subscription = null; purchased = {}; await store.clearAccountAccess(); notifyListeners(); }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
