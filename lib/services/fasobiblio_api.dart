import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/book.dart';
import '../models/session.dart';
import '../models/app_notification.dart';

class FasobiblioApi {
  static const database = 'https://alifam-hub-1b32a-default-rtdb.europe-west1.firebasedatabase.app';
  static const api = 'https://fasobiblio-api.onrender.com';
  static const firebaseKey = 'AIzaSyDdHVlNZNXmBPo26EScIKtVD0vDvLwvTiA';
  static const _sessionKey = 'fasobiblio.flutter.session';
  UserSession? _session;

  UserSession? get session => _session;

  Future<dynamic> _request(Uri uri, {String method = 'GET', Map<String, String>? headers, Object? body, Duration timeout = const Duration(seconds: 30)}) async {
    final allHeaders = {'Accept': 'application/json', ...?headers};
    final response = await (switch (method) {
      'POST' => http.post(uri, headers: allHeaders, body: body),
      'PUT' => http.put(uri, headers: allHeaders, body: body),
      'PATCH' => http.patch(uri, headers: allHeaders, body: body),
      'DELETE' => http.delete(uri, headers: allHeaders, body: body),
      _ => http.get(uri, headers: allHeaders),
    }).timeout(timeout);
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

  Future<UserSession> signup(String pseudo, String password, String phone, {String phoneCountry = 'BF'}) async {
    final check = await _request(Uri.parse('$api/api/check-username?pseudo=${Uri.encodeQueryComponent(pseudo)}'));
    if (check['available'] != true) throw Exception('Ce pseudo est déjà utilisé.');
    final data = await _request(Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$firebaseKey'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': _email(pseudo), 'password': password, 'returnSecureToken': true}));
    final next = await _persist(_fromAuth(Map<String, dynamic>.from(data), pseudo: pseudo.trim(), anonymous: false));
    await authenticated('/api/register-recovery', method: 'POST', body: {'pseudo': pseudo, 'phone': phone, 'phoneCountry': phoneCountry});
    return next;
  }

  Future<String> recoverAccount(String pseudo, String phone, String country) async {
    final data = await _request(Uri.parse('$api/api/recover-account'), method: 'POST',
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'pseudo': pseudo.trim(), 'phone': phone, 'phoneCountry': country}));
    final code = data['resetCode'];
    if (code is! String || code.isEmpty) throw Exception('Récupération indisponible.');
    return code;
  }
  Future<void> resetPassword(String code, String password) async {
    await _request(Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:resetPassword?key=$firebaseKey'), method: 'POST',
      headers: {'Content-Type': 'application/json'}, body: jsonEncode({'oobCode': code, 'newPassword': password}));
  }

  Future<UserSession> logout() async {
    _session = null;
    await (await SharedPreferences.getInstance()).remove(_sessionKey);
    try { return await _guest(); } catch (_) { return UserSession.offlineGuest(); }
  }

  Future<dynamic> authenticated(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise pour cette action.');
    return _request(Uri.parse('$api$path'), method: method, headers: {'Content-Type': 'application/json', 'Authorization': 'Bearer ${auth.idToken}'}, body: body == null ? null : jsonEncode(body));
  }

  Future<List<Book>> catalog() async {
    final data = await _request(Uri.parse('$database/documents.json'), timeout: const Duration(seconds: 30));
    if (data is! Map) return [];
    return data.entries.where((entry) {
      final value = entry.value;
      return value is Map && value['active'] != false && value['published'] != false;
    }).map((entry) => Book.fromJson('${entry.key}', Map<String, dynamic>.from(entry.value))).toList();
  }

  Future<List<AppNotification>> notifications() async {
    final data = await _request(Uri.parse('$database/notifications.json'), timeout: const Duration(seconds: 12));
    if (data is! Map) return [];
    final values = data.entries.where((entry) => entry.value is Map).map((entry) => AppNotification.fromJson('${entry.key}', Map<String, dynamic>.from(entry.value))).toList();
    values.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<Map<String, dynamic>> setting(String path) async {
    final encodedPath = path.split('/').where((part) => part.isNotEmpty).map(Uri.encodeComponent).join('/');
    final data = await _request(Uri.parse('$database/$encodedPath.json'), timeout: const Duration(seconds: 12));
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<void> markNotificationRead(String notificationId) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise.');
    await _request(Uri.parse('$database/notif_reads/${Uri.encodeComponent(auth.uid)}/${Uri.encodeComponent(notificationId)}.json?auth=${Uri.encodeQueryComponent(auth.idToken)}'), method: 'PUT', headers: {'Content-Type': 'application/json'}, body: 'true');
  }

  Future<void> markAllNotificationsRead(Iterable<String> ids) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise.');
    final values = <String, bool>{for (final id in ids) id: true};
    await _request(Uri.parse('$database/notif_reads/${Uri.encodeComponent(auth.uid)}.json?auth=${Uri.encodeQueryComponent(auth.idToken)}'), method: 'PATCH', headers: {'Content-Type': 'application/json'}, body: jsonEncode(values));
  }

  Future<List<DocumentReview>> reviews(String documentId) async {
    final data = await _request(Uri.parse('$database/document_reviews/${Uri.encodeComponent(documentId)}.json'), timeout: const Duration(seconds: 12));
    if (data is! Map) return [];
    return data.entries.where((entry) => entry.value is Map).map((entry) => DocumentReview.fromJson('${entry.key}', Map<String, dynamic>.from(entry.value))).toList();
  }

  Future<void> submitReview(String documentId, int stars, String comment) async {
    final auth = await ensureSession();
    if (auth.anonymous || auth.idToken.isEmpty) throw Exception('Connectez-vous avec votre compte pour publier un avis.');
    await _request(Uri.parse('$database/document_reviews/${Uri.encodeComponent(documentId)}/${Uri.encodeComponent(auth.uid)}.json?auth=${Uri.encodeQueryComponent(auth.idToken)}'), method: 'PUT', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'stars': stars, 'comment': comment.trim(), 'name': auth.pseudo, 'ts': DateTime.now().millisecondsSinceEpoch, 'status': 'pending'}));
  }

  Future<void> sendSupportMessage({required String type, required String message, required String email}) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise.');
    await authenticated('/api/contact', method: 'POST', body: {'nom':auth.anonymous?'Lecteur invité':auth.pseudo,'email':email.trim(),'message':message.trim(),'type':type});
  }

  Future<void> sendSuggestion({required String title, required String subject, required String level, required String details}) async {
    final auth = await ensureSession();
    if (auth.idToken.isEmpty) throw Exception('Connexion Internet requise.');
    await _request(Uri.parse('$database/suggestions.json?auth=${Uri.encodeQueryComponent(auth.idToken)}'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'name': auth.anonymous ? 'Lecteur invité' : auth.pseudo, 'title': title.trim(), 'subject': subject.trim(), 'level': level.trim(), 'details': details.trim(), 'status': 'pending', 'createdAt': DateTime.now().millisecondsSinceEpoch}));
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
    final data = await authenticated('/api/pay', method: 'POST', body: {'docId': docId, 'numeroSend': phone.replaceAll(RegExp(r'\D'), ''), 'nomclient': pseudo, 'pseudo': pseudo});
    return {'token': '${data['token'] ?? ''}', 'url': '${data['url'] ?? ''}'};
  }

  Future<Map<String, String>> startSubscriptionPayment({required String planId, required String phone, required String pseudo}) async {
    final data = await authenticated('/api/pay-subscription', method: 'POST', body: {'planId': planId, 'numeroSend': phone.replaceAll(RegExp(r'\D'), ''), 'pseudo': pseudo});
    return {'token': '${data['token'] ?? ''}', 'url': '${data['url'] ?? ''}'};
  }

  Future<Map<String, String>> startDonationPayment({required int amount, required String phone, required String pseudo}) async {
    final data = await authenticated('/api/donate', method: 'POST', body: {
      'pseudo': pseudo,
      'montant': amount,
      'numeroSend': phone.replaceAll(RegExp(r'\D'), ''),
      'nomclient': pseudo,
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

  Future<String> assistant(String question, {String? documentContext, String task = 'question', int points = 5, List<Map<String,dynamic>> history = const []}) async {
    final data = await _request(Uri.parse('$api/api/chat'), method: 'POST', headers: {'Content-Type': 'application/json'}, body: jsonEncode({'systemPrompt': 'Tu es l’assistant pédagogique de Fasobiblio. Réponds clairement en français. Utilise du Markdown propre pour structurer la réponse : titres, listes, gras, italique et liens si utile. Ne montre jamais les marqueurs Markdown sans raison.', 'userPrompt': question, 'documentContext': documentContext, 'task': task, 'points': points, 'history': history, 'max_completion_tokens': 1800, 'temperature': .3}), timeout: const Duration(seconds: 50));
    return '${data['text'] ?? data['answer'] ?? data['response'] ?? 'Réponse indisponible.'}';
  }
}
