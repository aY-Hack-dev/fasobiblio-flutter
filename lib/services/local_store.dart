import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/book.dart';

class LocalStore {
  static const favoritesKey='fasobiblio.flutter.favorites',laterKey='fasobiblio.flutter.later',catalogKey='fasobiblio.flutter.catalog',lastSyncKey='fasobiblio.flutter.lastSync',accountAccessKey='fasobiblio.flutter.accountAccess',darkModeKey='fasobiblio.flutter.darkMode',themeModeKey='fasobiblio.flutter.themeMode',notificationsKey='fasobiblio.flutter.notifications',notificationReadsKey='fasobiblio.flutter.notificationReads',welcomeSeenKey='fasobiblio.flutter.welcomeSeen',lastOpenedDocumentKey='fasobiblio.flutter.lastOpenedDocument';
  Future<Set<String>> load(String key) async=>(await SharedPreferences.getInstance()).getStringList(key)?.toSet()??<String>{};
  Future<void> save(String key,Set<String> values) async=>(await SharedPreferences.getInstance()).setStringList(key,values.toList());
  Future<List<Book>> loadCatalog() async{final raw=(await SharedPreferences.getInstance()).getString(catalogKey);if(raw==null||raw.isEmpty)return[];try{final decoded=jsonDecode(raw);if(decoded is! List)return[];return decoded.whereType<Map>().map((item){final value=Map<String,dynamic>.from(item);return Book.fromJson('${value['id']??''}',value);}).where((book)=>book.id.isNotEmpty).toList();}catch(_){return[];}}
  Future<void> saveCatalog(List<Book> books) async{final prefs=await SharedPreferences.getInstance();await prefs.setString(catalogKey,jsonEncode(books.map((book)=>book.toJson()).toList()));await prefs.setInt(lastSyncKey,DateTime.now().millisecondsSinceEpoch);}
  Future<DateTime?> lastSync() async{final value=(await SharedPreferences.getInstance()).getInt(lastSyncKey);return value==null?null:DateTime.fromMillisecondsSinceEpoch(value);}
  Future<Map<String,dynamic>> loadAccountAccess() async{final raw=(await SharedPreferences.getInstance()).getString(accountAccessKey);if(raw==null||raw.isEmpty)return{};try{final decoded=jsonDecode(raw);return decoded is Map?Map<String,dynamic>.from(decoded):{};}catch(_){return{};}}
  Future<void> saveAccountAccess(Map<String,dynamic>? subscription,Set<String> purchased) async=>await(await SharedPreferences.getInstance()).setString(accountAccessKey,jsonEncode({'subscription':subscription,'purchased':purchased.toList()}));
  Future<void> clearAccountAccess() async=>(await SharedPreferences.getInstance()).remove(accountAccessKey);
  Future<bool> loadDarkMode() async=>(await SharedPreferences.getInstance()).getBool(darkModeKey)??false;
  Future<void> saveDarkMode(bool value) async=>(await SharedPreferences.getInstance()).setBool(darkModeKey,value);
  Future<String> loadThemeMode() async{final prefs=await SharedPreferences.getInstance();return prefs.getString(themeModeKey)??((prefs.getBool(darkModeKey)??false)?'dark':'system');}
  Future<void> saveThemeMode(String value) async=>(await SharedPreferences.getInstance()).setString(themeModeKey,value);
  String assistantMemoryKey(String accountKey)=>'fasobiblio.flutter.assistant.${accountKey.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'),'_')}';
  Future<List<Map<String,dynamic>>> loadAssistantMemory(String accountKey) async{final value=await loadJson(assistantMemoryKey(accountKey));if(value is! List)return[];return value.whereType<Map>().map((e)=>Map<String,dynamic>.from(e)).toList();}
  Future<void> saveAssistantMemory(String accountKey,List<Map<String,dynamic>> messages) async=>saveJson(assistantMemoryKey(accountKey),messages.take(80).toList());
  Future<dynamic> loadJson(String key) async{final raw=(await SharedPreferences.getInstance()).getString(key);if(raw==null||raw.isEmpty)return null;try{return jsonDecode(raw);}catch(_){return null;}}
  Future<void> saveJson(String key,Object value) async=>(await SharedPreferences.getInstance()).setString(key,jsonEncode(value));
  Future<bool> loadWelcomeSeen() async=>(await SharedPreferences.getInstance()).getBool(welcomeSeenKey)??false;
  Future<void> saveWelcomeSeen() async=>(await SharedPreferences.getInstance()).setBool(welcomeSeenKey,true);
}
