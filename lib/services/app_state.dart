import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/book.dart';
import '../models/app_notification.dart';
import '../models/session.dart';
import 'fasobiblio_api.dart';
import 'local_store.dart';

class AppState extends ChangeNotifier {
  AppState(this.api,this.store); final FasobiblioApi api; final LocalStore store;
  List<Book> books=[]; List<dynamic> offers=[]; Set<String> favorites={},later={},purchased={},notificationReads={}; UserSession? session; Map<String,dynamic>? subscription; List<AppNotification> notifications=[]; String? lastOpenedBookId; bool loading=true,refreshing=false,offline=false,welcomeSeen=false,_hydrated=false; DateTime? lastSync; String? error; String themeMode='system'; StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _retry;
  bool _loadingRequest = false;
  bool _extrasLoading = false;
  int _retrySeconds = 5;
  bool get catalogPending => books.isEmpty && (loading || refreshing || offline || lastSync == null);
  bool get darkMode=>themeMode=='dark';
  int get unreadNotifications=>notifications.where((item)=>!notificationReads.contains(item.id)).length;
  String get assistantAccountKey=>(session!=null&&!session!.anonymous&&session!.pseudo.isNotEmpty)?session!.pseudo:'guest';
  Book? get lastOpenedBook{final id=lastOpenedBookId;if(id==null||id.isEmpty)return null;for(final book in books){if(book.id==id)return book;}return null;}
  Future<void> startConnectivityMonitoring() async{final connectivity=Connectivity();_connectivitySubscription??=connectivity.onConnectivityChanged.listen((results){final connected=results.isNotEmpty&&!results.contains(ConnectivityResult.none);if(!connected){offline=true;notifyListeners();}else if(offline&&!refreshing){load(refresh:true);}});}
  Future<void> load({bool refresh=false}) async{if(_loadingRequest)return;_loadingRequest=true;_retry?.cancel();refresh?refreshing=true:loading=true;error=null;notifyListeners();if(!_hydrated){final local=await Future.wait([store.loadCatalog(),store.load(LocalStore.favoritesKey),store.load(LocalStore.laterKey),store.lastSync(),store.loadAccountAccess(),store.loadThemeMode(),store.loadJson(LocalStore.notificationsKey),store.load(LocalStore.notificationReadsKey),store.loadWelcomeSeen(),store.loadJson(LocalStore.lastOpenedDocumentKey)]);books=local[0] as List<Book>;favorites=local[1] as Set<String>;later=local[2] as Set<String>;lastSync=local[3] as DateTime?;final access=local[4] as Map<String,dynamic>;subscription=access['subscription'] is Map?Map<String,dynamic>.from(access['subscription']):null;purchased=(access['purchased'] is List?access['purchased'] as List:const[]).map((id)=>'$id').where((id)=>id.isNotEmpty).toSet();themeMode=local[5] as String;final cached=local[6];if(cached is List)notifications=cached.whereType<Map>().map((item)=>AppNotification.fromJson('${item['id']??''}',Map<String,dynamic>.from(item))).where((item)=>item.id.isNotEmpty).toList();notificationReads=local[7] as Set<String>;welcomeSeen=local[8] as bool;final opened=local[9];if(opened is Map)lastOpenedBookId='${opened['id']??''}'.trim();session??=UserSession.offlineGuest();_hydrated=true;loading=false;refreshing=true;notifyListeners();}
    try {
      // Publish the catalog immediately, independent of session and other services.
      final catalog = await api.catalog();
      books = catalog; offline = false; loading = false;
      lastSync = DateTime.now(); _retrySeconds = 5; notifyListeners();
      await store.saveCatalog(books);
    } catch (_) {
      offline = true;
      error = 'Chargement des documents échoué. Vérifiez votre connexion.';
      _retry = Timer(Duration(seconds: _retrySeconds), () => load(refresh: true));
      _retrySeconds = (_retrySeconds * 2).clamp(5, 60);
    } finally {
      loading = false; refreshing = false; _loadingRequest = false; notifyListeners();
    }
    if (!offline) unawaited(_loadExtras());
  }
  Future<void> _loadExtras() async {
    if (_extrasLoading) return;
    _extrasLoading = true;
    await Future.wait([
      (() async { try { session = await api.ensureSession(); await _refreshAccount(); } catch (_) {} })(),
      (() async { try { offers = await api.plans(); notifyListeners(); } catch (_) {} })(),
      (() async { try { notifications = await api.notifications(); notifyListeners(); await store.saveJson(LocalStore.notificationsKey, notifications.map((e) => e.toJson()).toList()); } catch (_) {} })(),
    ]);
    _extrasLoading = false;
  }
  Future<void> toggleFavorite(String id) async{favorites.contains(id)?favorites.remove(id):favorites.add(id);notifyListeners();await store.save(LocalStore.favoritesKey,favorites);}
  Future<void> toggleLater(String id) async{later.contains(id)?later.remove(id):later.add(id);notifyListeners();await store.save(LocalStore.laterKey,later);}
  Future<void> markDocumentOpened(String id) async{if(id.isEmpty)return;lastOpenedBookId=id;notifyListeners();await store.saveJson(LocalStore.lastOpenedDocumentKey,{'id':id,'openedAt':DateTime.now().toIso8601String()});}
  Future<void> setThemeMode(String value) async{if(!const{'system','light','dark'}.contains(value))return;themeMode=value;notifyListeners();await store.saveThemeMode(value);}
  Future<void> toggleDarkMode(bool value)=>setThemeMode(value?'dark':'light');
  Future<void> completeWelcome() async{welcomeSeen=true;notifyListeners();await store.saveWelcomeSeen();}
  Future<void> markNotificationRead(String id) async{notificationReads.add(id);notifyListeners();await store.save(LocalStore.notificationReadsKey,notificationReads);if(!offline)await api.markNotificationRead(id);}
  Future<void> markAllNotificationsRead() async{notificationReads.addAll(notifications.map((e)=>e.id));notifyListeners();await store.save(LocalStore.notificationReadsKey,notificationReads);if(!offline)await api.markAllNotificationsRead(notifications.map((e)=>e.id));}
  bool hasAccess(Book book)=>!book.isPremium||purchased.contains(book.id)||subscription!=null;
  Future<void> _refreshAccount({bool notify=true}) async{if(session==null||session!.anonymous){subscription=null;purchased={};if(notify)notifyListeners();return;}try{final values=await Future.wait([api.mySubscription(),api.myDocuments()]);subscription=values[0] as Map<String,dynamic>?;purchased=(values[1] as List<dynamic>).whereType<Map>().map((e)=>'${e['docId']??''}').where((id)=>id.isNotEmpty).toSet();await store.saveAccountAccess(subscription,purchased);}catch(_){}finally{if(notify)notifyListeners();}}
  Future<void> refreshAccount()=>_refreshAccount();
  Future<void> login(String pseudo,String password) async{session=await api.login(pseudo,password);await _refreshAccount();}
  Future<void> signup(String pseudo,String password,String phone) async{session=await api.signup(pseudo,password,phone);await _refreshAccount();}
  Future<void> logout() async{session=await api.logout();subscription=null;purchased={};await store.clearAccountAccess();notifyListeners();}
  @override void dispose(){_retry?.cancel();_connectivitySubscription?.cancel();super.dispose();}
}
