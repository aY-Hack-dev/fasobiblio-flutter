import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Commits complete byte ranges only. A failed range is retried, never appended
/// twice. If-Range prevents joining bytes from different file versions.
class ResumableDownload {
  const ResumableDownload({
    this.chunkSize = 1024 * 1024,
    this.retryDelay = const Duration(seconds: 2),
  });
  final int chunkSize;
  final Duration retryDelay;

  Future<void> fetch(
    Uri uri,
    File destination, {
    required http.Client client,
    void Function(double)? onProgress,
  }) async {
    final partial = File('${destination.path}.part');
    final metadata = File('${destination.path}.part.json');
    var offset = 0;
    int? total;
    String? validator;
    try {
      if (await metadata.exists() && await partial.exists()) {
        final saved = jsonDecode(await metadata.readAsString()) as Map;
        // Signed query parameters can expire without changing the resource.
        if (saved['resource'] == '${uri.origin}${uri.path}' &&
            saved['validator'] is String) {
          validator = saved['validator'] as String;
          offset = saved['offset'] as int;
          total = saved['total'] as int?;
          if (await partial.length() < offset ||
              offset < 0 ||
              (total != null && offset > total)) {
            offset = 0;
          }
        }
      }
    } catch (_) {
      offset = 0;
      validator = null;
      total = null;
    }
    final output = await partial.open(mode: FileMode.append);
    try {
      await output.truncate(offset);
      await output.setPosition(offset);
      var failures = 0;
      while (total == null || offset < total) {
        final start = offset;
        try {
          final end = total == null
              ? start + chunkSize - 1
              : math.min(start + chunkSize - 1, total - 1);
          final request = http.Request('GET', uri)
            ..headers['Range'] = 'bytes=$start-$end';
          request.headers['Accept-Encoding'] = 'identity';
          if (start > 0 && validator != null) {
            request.headers['If-Range'] = validator;
          }
          final response = await client
              .send(request)
              .timeout(const Duration(seconds: 25));
          if (response.statusCode == 408 ||
              response.statusCode == 429 ||
              response.statusCode >= 500) {
            await response.stream.drain<void>();
            throw const SocketException('Serveur temporairement indisponible');
          }
          if (response.statusCode != 200 && response.statusCode != 206) {
            await response.stream.drain<void>();
            throw HttpException(
              'Téléchargement impossible (${response.statusCode}).',
            );
          }
          final etag = response.headers['etag'];
          final nextValidator = etag != null && !etag.startsWith('W/')
              ? etag
              : response.headers['last-modified'];
          int? expected;
          if (response.statusCode == 206) {
            final range = RegExp(r'^bytes (\d+)-(\d+)/(\d+)$')
                .firstMatch(response.headers['content-range'] ?? '');
            if (range == null ||
                int.parse(range[1]!) != start ||
                int.parse(range[2]!) > end ||
                int.parse(range[2]!) < start ||
                int.parse(range[3]!) <= int.parse(range[2]!)) {
              await response.stream.drain<void>();
              throw const HttpException('Plage de téléchargement invalide.');
            }
            final nextTotal = int.parse(range[3]!);
            if (start > 0 &&
                ((total != null && total != nextTotal) ||
                    (validator != null &&
                        nextValidator != null &&
                        validator != nextValidator))) {
              await response.stream.drain<void>();
              offset = 0;
              total = null;
              validator = null;
              await output.truncate(0);
              await output.setPosition(0);
              if (await metadata.exists()) await metadata.delete();
              continue;
            }
            total = nextTotal;
            expected = int.parse(range[2]!) - start + 1;
          } else {
            // Range unsupported or resource changed: replace, never append.
            offset = 0;
            await output.truncate(0);
            await output.setPosition(0);
            total = response.contentLength;
            expected = response.contentLength;
            if (await metadata.exists()) await metadata.delete();
          }
          validator = nextValidator;
          var received = 0;
          var lastUpdate = DateTime.fromMillisecondsSinceEpoch(0);
          await for (final bytes in response.stream.timeout(
            const Duration(seconds: 25),
          )) {
            received += bytes.length;
            if (expected != null && received > expected) {
              throw const HttpException('Taille du document invalide.');
            }
            await output.writeFrom(bytes);
            if (total != null &&
                total > 0 &&
                DateTime.now().difference(lastUpdate).inMilliseconds >= 150) {
              onProgress?.call(((offset + received) / total).clamp(0.0, 1.0));
              lastUpdate = DateTime.now();
            }
          }
          if (received == 0 || (expected != null && received != expected)) {
            throw const SocketException('Bloc incomplet');
          }
          offset += received;
          if (response.statusCode == 200) total = offset;
          await output.flush();
          await metadata.writeAsString(
            jsonEncode({
              'resource': '${uri.origin}${uri.path}',
              'offset': offset,
              'total': total,
              'validator': validator,
            }),
            flush: true,
          );
          failures = 0;
          if (total != null) onProgress?.call(offset / total);
        } on Object catch (error) {
          // Restore the last committed boundary after a partial stream failure.
          await output.truncate(offset);
          await output.setPosition(offset);
          final retryable =
              error is SocketException ||
              error is TimeoutException ||
              error is http.ClientException;
          if (!retryable || ++failures > 4) rethrow;
          await Future<void>.delayed(retryDelay * failures);
        }
      }
    } finally {
      await output.close();
    }
    final header = await partial.open();
    try {
      if (String.fromCharCodes(await header.read(5)) != '%PDF-') {
        if (await metadata.exists()) await metadata.delete();
        throw const FormatException('Le fichier reçu n’est pas un PDF valide.');
      }
    } finally {
      await header.close();
    }
    await partial.rename(destination.path);
    if (await metadata.exists()) await metadata.delete();
    onProgress?.call(1);
  }
}
