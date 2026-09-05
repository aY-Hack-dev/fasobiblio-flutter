import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadTask {
  DownloadTask(this.url, this.key);
  final String url, key;
  double? progress;
  String? error;
  bool running = true;
}
class DocumentService {
  static final tasks = ValueNotifier<List<DownloadTask>>([]);
  static final Map<String, Future<String>> _pending = {};
  static Future<void> _queue = Future.value();

  Future<String> ensureLocal(String raw, String cacheKey, {void Function(double)? onProgress}) {
    final pending = _pending[cacheKey];
    if (pending != null) return pending;
    final job = _queue.then((_) => _download(raw, cacheKey, onProgress: onProgress));
    _pending[cacheKey] = job;
    _queue = job.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return job.whenComplete(() => _pending.remove(cacheKey));
  }

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

  Future<String> _download(String raw, String cacheKey, {void Function(double)? onProgress}) async {
    final existing = await cached(cacheKey);
    if (existing != null) {
      onProgress?.call(1);
      return existing;
    }
    final task = DownloadTask(raw, cacheKey);
    tasks.value = [...tasks.value.where((t) => t.key != cacheKey).take(19), task];
    final client = http.Client();
    IOSink? sink;
    File? partial;
    try {
      final response = await client.send(http.Request('GET', validate(raw))).timeout(const Duration(seconds: 45));
      if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Téléchargement impossible (${response.statusCode}).');
      final file = await _cacheFile(cacheKey);
      partial = File('${file.path}.part');
      sink = partial.openWrite();
      var received = 0;
      var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
      await for (final chunk in response.stream.timeout(const Duration(seconds: 45))) {
        received += chunk.length;
        sink.add(chunk);
        await sink.flush();
        if (response.contentLength != null && response.contentLength! > 0) {
          task.progress = (received / response.contentLength!).clamp(0.0, 1.0);
          if (DateTime.now().difference(lastUpdate).inMilliseconds > 150) {
            onProgress?.call(task.progress!); tasks.value = [...tasks.value]; lastUpdate = DateTime.now();
          }
        }
      }
      await sink.close(); sink = null;
      if (received == 0 || (response.contentLength != null && received != response.contentLength)) throw Exception('Téléchargement incomplet. Réessayez.');
      final header = await partial.open();
      try {
        final bytes = await header.read(5);
        if (String.fromCharCodes(bytes) != '%PDF-') throw Exception('Le fichier reçu n’est pas un PDF valide.');
      } finally { await header.close(); }
      await partial.rename(file.path);
      task.progress = 1; onProgress?.call(1);
      return file.path;
    } catch (e) {
      task.error = 'Téléchargement interrompu. Réessayez.';
      rethrow;
    } finally {
      await sink?.close();
      client.close();
      if (partial != null && await partial.exists()) await partial.delete();
      task.running = false; tasks.value = [...tasks.value];
    }
  }

  Future<String> exportToDownloads(String localPath, String name) async {
    if (!Platform.isAndroid) throw Exception('L’export dans Téléchargements est disponible sur Android.');
    final result = await _downloads.invokeMethod<String>('saveToDownloads', {'path': localPath, 'name': safeName(name)});
    if (result == null || result.isEmpty) throw Exception('Impossible d’enregistrer le document.');
    return result;
  }
}
