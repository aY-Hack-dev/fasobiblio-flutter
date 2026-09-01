import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentService {
  static const _downloads = MethodChannel('com.fasobiblio.app/downloads');
  static const allowedHosts = {'fasobiblio-api.onrender.com', 'fasobiblio.com', 'www.fasobiblio.com', 'repzbcmqtpjnqdbvlvgt.supabase.co'};

  Uri validate(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || !allowedHosts.contains(uri.host.toLowerCase())) throw Exception('Adresse du document non autorisée.');
    return uri;
  }

  String safeName(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ._ -]'), '_').trim();
    final base = cleaned.isEmpty ? 'document' : cleaned;
    final limited = base.length > 110 ? base.substring(0, 110).trim() : base;
    return limited.toLowerCase().endsWith('.pdf') ? limited : '$limited.pdf';
  }

  Future<File> _cacheFile(String name) async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/documents');
    if (!await directory.exists()) await directory.create(recursive: true);
    return File('${directory.path}/${safeName(name)}');
  }

  Future<String?> cached(String cacheKey) async {
    final file = await _cacheFile(cacheKey);
    return await file.exists() && await file.length() > 0 ? file.path : null;
  }

  Future<String> ensureLocal(String raw, String cacheKey, {void Function(double)? onProgress}) async {
    final existing = await cached(cacheKey);
    if (existing != null) {
      onProgress?.call(1);
      return existing;
    }
    final uri = validate(raw);
    final request = http.Request('GET', uri);
    final response = await request.send().timeout(const Duration(seconds: 45));
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Téléchargement impossible (${response.statusCode}).');
    final file = await _cacheFile(cacheKey);
    final partial = File('${file.path}.part');
    var received = 0;
    try {
      final partialSink = partial.openWrite();
      await for (final chunk in response.stream) {
        received += chunk.length;
        partialSink.add(chunk);
        if (response.contentLength != null && response.contentLength! > 0) onProgress?.call(received / response.contentLength!);
      }
      await partialSink.close();
      if (await file.exists()) await file.delete();
      await partial.rename(file.path);
    } catch (_) {
      if (await partial.exists()) await partial.delete();
      rethrow;
    }
    return file.path;
  }

  Future<String> exportToDownloads(String localPath, String name) async {
    if (!Platform.isAndroid) throw Exception('L’export dans Téléchargements est disponible sur Android.');
    final result = await _downloads.invokeMethod<String>('saveToDownloads', {'path': localPath, 'name': safeName(name)});
    if (result == null || result.isEmpty) throw Exception('Impossible d’enregistrer le document.');
    return result;
  }
}
