import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/session.dart';

class FasobiblioApi {
  static const database = 'https://alifam-hub-1b32a-default-rtdb.europe-west1.firebasedatabase.app';
  static const api = 'https://fasobiblio-api.onrender.com';
  static const firebaseKey = 'AIzaSyDdHVlNZNXmBPo26EScIKtVD0vDvLwvTiA';
  static const _sessionKey = 'fasobiblio.flutter.session';
  UserSession? _session;

  UserSession? get session => _session;

  Future<dynamic> _request(Uri uri, {String method = 'GET', Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 30)}) async {
    final response = await (method == 'POST'
      ? http.post(uri, headers: {'Accept': 'application/json', ...?headers}, body: body)
      : http.get(uri, headers: {'Accept': 'application/json', ...?headers})).timeout(timeout);
    dynamic data;
    try { data = response.body.isEmpty ? <String, dynamic>{} : jsonDecode(response.body); }
    catch (_) { data = {'error': response.body}; }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final raw = data is Map ? data['error'] ?? data['message'] : data;
      final message = raw is Map ? raw['message'] : raw;
      throw Exception(_friendlyError('$message'));
    }
    return data;
  }

  String _friendlyError(String value) {
    if (value.contains('INVALID_LOGIN_CREDENTIALS')) return 'Pseudo ou mot de passe incorrect.';
    if (value.contains('EMAIL_EXISTS')) return 'Ce pseudo est déjà utilisé.';
    if (value.contains('WEAK_PASSWORD')) return 'Le mot de passe est trop faible.';
    return value.replaceFirst('Exception: ', '');
  }

  Future<UserSession> ensureSession() async {
    if (_session == null) {
      final raw = (await SharedPreferences.getInstance()).getString(_sessionKey);
      if (raw != null) {
        try { _session = UserSession.fromJson(jsonDecode(raw)); } catch (_) { _session = null; }
      }
    }
    if (_session == null) {
      try { return await _guest(); } catch (_) { return UserSession.offlineGuest(); }
    }
    if (_session!.expiresAt <= DateTime.now().millisecondsSinceEpoch) {
      try { return await _refresh(_session!); } catch (_) { return _guest(); }
    }
    return _session!;
  }

  UserSession _fromAuth(Map<String, dynamic> data, {String pseudo = '', bool anonymous = true}) => UserSession(
    idToken: '${data['idToken']}', refreshToken: '${data['refreshToken']}', uid: '${data['localId']}',
    expiresAt: DateTime.now().millisecondsSinceEpoch + ((num.tryParse('${data['expiresIn'] ?? 3600}') ?? 3600).toInt() * 1000) - 60000,
    pseudo: pseudo, anonymous: anonymous,
  );

  Future<UserSession> _persist(UserSession next) async {
    _session = next;
    await (await SharedPreferences.getInstance()).setString(_sessionKey, jsonEncode(next.toJson()));
    return next;
  }

  Future<UserSession> _guest() async {
    final data = await _request(Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseKey'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'returnSecureToken': true}));
    return _persist(_fromAuth(Map<String, dynamic>.from(data)));
  }

  Future<UserSession> _refresh(UserSession current) async {
    final data = await _request(Uri.parse('https://securetoken.googleapis.com/v1/token?key=$firebaseKey'), method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded'}, body: 'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(current.refreshToken)}');
    return _persist(UserSession(idToken: '${data['id_token']}', refreshToken: '${data['refresh_token']}', uid: '${data['user_id']}', expiresAt: DateTime.now().millisecondsSinceEpoch + ((num.tryParse('${data['expires_in'] ?? 3600}') ?? 3600).toInt() * 1000) - 60000, pseudo: current.pseudo, anonymous: current.anonymous));
  }

  String _email(String pseudo) => '${pseudo.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_.-]'), '')}@fasobiblio.local';

  Future<UserSession> login(String pseudo, String password) async {
    final data = await _request(Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$firebaseKey'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _email(pseudo), 'password': password, 'returnSecureToken': true}));
    return _persist(_fromAuth(Map<String, dynamic>.from(data), pseudo: pseudo.trim(), anonymous: false));
  }

  Future<UserSession> signup(String pseudo, String password, String phone) async {
    final check = await _request(Uri.parse('$api/api/check-username?pseudo=${Uri.encodeQueryComponent(pseudo)}'));
    if (check['available'] != true) throw Exception('Ce pseudo est déjà utilisé.');
    final data = await _request(Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseKey'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _email(pseudo), 'password': password, 'returnSecureToken': true}));
    final next = await _persist(_fromAuth(Map<String, dynamic>.from(data), pseudo: pseudo.trim(), anonymous: false));
    await authenticated('/api/register-recovery', method: 'POST', body: {'pseudo': pseudo, 'phone': phone.replaceAll(RegExp(r'\D'), ''), 'phoneCountry': 'BF'});
    return next;
  }

  Future<UserSession> logout() async {
    _session = null;
    await (await SharedPreferences.getInstance()).remove(_sessionKey);
    return _guest();
  }

  Future<dynamic> authenticated(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise pour cette action.');
    return _request(Uri.parse('$api$path'), method: method, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.idToken}'}, body: body == null ? null : jsonEncode(body));
  }

  Future<List<Book>> catalog() async {
    final data = await _request(Uri.parse('$database/documents.json'), timeout: const Duration(seconds: 12));
    if (data is! Map) return [];
    return data.entries.where((entry) {
      final value = entry.value;
      return value is Map && value['active'] != false && value['published'] != false;
    }).map((entry) => Book.fromJson('${entry.key}', Map<String, dynamic>.from(entry.value))).toList();
  }

  Future<Map<String, String>> documentFile(String id, String mode) async {
    final data = await authenticated('/api/doc-file?docId=${Uri.encodeQueryComponent(id)}&mode=$mode');
    return {'url': '${data['fileUrl'] ?? data['file_url'] ?? ''}', 'name': '${data['fileName'] ?? data['file_name'] ?? 'Document.pdf'}'};
  }

  Future<List<dynamic>> plans() async {
    final data = await _request(Uri.parse('$api/api/subscription-plans'));
    return data is Map && data['plans'] is List ? data['plans'] : [];
  }

  Future<Map<String, String>> startDocumentPayment({required String docId, required String phone, required String pseudo}) async {
    final data = await authenticated('/api/pay', method: 'POST', body: {
      'docId': docId,
      'numeroSend': phone.replaceAll(RegExp(r'\D'), ''),
      'nomclient': pseudo,
      'pseudo': pseudo,
    });
    return {'token': '${data['token'] ?? ''}', 'url': '${data['url'] ?? ''}'};
  }

  Future<Map<String, String>> startSubscriptionPayment({required String planId, required String phone, required String pseudo}) async {
    final data = await authenticated('/api/pay-subscription', method: 'POST', body: {
      'planId': planId,
      'numeroSend': phone.replaceAll(RegExp(r'\D'), ''),
      'pseudo': pseudo,
    });
    return {'token': '${data['token'] ?? ''}', 'url': '${data['url'] ?? ''}'};
  }

  Future<bool> checkAccess(String docId) async {
    final data = await authenticated('/api/check-access?docId=${Uri.encodeQueryComponent(docId)}');
    return data is Map && data['access'] == true;
  }

  Future<List<dynamic>> myDocuments() async {
    final data = await authenticated('/api/my-documents');
    return data is Map && data['documents'] is List ? data['documents'] : [];
  }

  Future<Map<String, dynamic>?> mySubscription() async {
    final data = await authenticated('/api/my-subscription');
    return data is Map && data['subscription'] is Map ? Map<String, dynamic>.from(data['subscription']) : null;
  }

  Future<String> assistant(String question) async {
    final data = await _request(Uri.parse('$api/api/chat'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'systemPrompt': 'Tu es l’assistant pédagogique de Fasobiblio. Réponds clairement en français.', 'userPrompt': question, 'max_completion_tokens': 700, 'temperature': .3}), timeout: const Duration(seconds: 50));
    return '${data['text'] ?? data['answer'] ?? data['response'] ?? 'Réponse indisponible.'}';
  }
}
