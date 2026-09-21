import 'dart:io';
import 'dart:async';

import 'resumable_download.dart';

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

  Future<String> ensureLocal(
    String raw,
    String cacheKey, {
    void Function(double)? onProgress,
  }) {
    final pending = _pending[cacheKey];
    if (pending != null) return pending;
    final job = _download(raw, cacheKey, onProgress: onProgress);
    _pending[cacheKey] = job;
    return job.whenComplete(() => _pending.remove(cacheKey));
  }

  static const _downloads = MethodChannel('com.fasobiblio.app/downloads');
  static const allowedHosts = {
    'fasobiblio-api.onrender.com',
    'fasobiblio.com',
    'www.fasobiblio.com',
    'repzbcmqtpjnqdbvlvgt.supabase.co',
  };

  Uri validate(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        !allowedHosts.contains(uri.host.toLowerCase()))
      throw Exception('Adresse du document non autorisée.');
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

  Future<String> _download(
    String raw,
    String cacheKey, {
    void Function(double)? onProgress,
  }) async {
    final existing = await cached(cacheKey);
    if (existing != null) {
      onProgress?.call(1);
      return existing;
    }
    final task = DownloadTask(raw, cacheKey);
    tasks.value = [
      ...tasks.value.where((t) => t.key != cacheKey).take(19),
      task,
    ];
    final client = http.Client();
    try {
      final file = await _cacheFile(cacheKey);
      await const ResumableDownload().fetch(
        validate(raw),
        file,
        client: client,
        onProgress: (value) {
          task.progress = value;
          onProgress?.call(value);
          tasks.value = [...tasks.value];
        },
      );
      return file.path;
    } catch (_) {
      task.error = 'Connexion interrompue. Les blocs reçus sont conservés pour la reprise.';
      rethrow;
    } finally {
      client.close();
      task.running = false;
      tasks.value = [...tasks.value];
    }
  }

  Future<String> exportToDownloads(String localPath, String name) async {
    if (!Platform.isAndroid)
      throw Exception(
        'L’export dans Téléchargements est disponible sur Android.',
      );
    final result = await _downloads.invokeMethod<String>('saveToDownloads', {
      'path': localPath,
      'name': safeName(name),
    });
    if (result == null || result.isEmpty)
      throw Exception('Impossible d’enregistrer le document.');
    return result;
  }
}
