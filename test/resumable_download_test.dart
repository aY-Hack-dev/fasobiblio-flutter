import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fasobiblio/services/resumable_download.dart';

void main() {
  late Directory root;
  late File target;
  final uri = Uri.parse('https://fasobiblio.com/test.pdf');
  final data = utf8.encode('%PDF-1.7\n0123456789abcdef');
  setUp(() async {
    root = await Directory.systemTemp.createTemp('fasobiblio-resume-');
    target = File('${root.path}/book.pdf');
  });
  tearDown(() async => root.delete(recursive: true));
  http.StreamedResponse range(http.BaseRequest request, List<int> bytes) {
    final match = RegExp(r'bytes=(\d+)-(\d+)')
        .firstMatch(request.headers['Range']!)!;
    final start = int.parse(match[1]!);
    final end = int.parse(match[2]!).clamp(0, bytes.length - 1);
    return http.StreamedResponse(
      Stream.value(bytes.sublist(start, end + 1)),
      206,
      headers: {
        'content-range': 'bytes $start-$end/${bytes.length}',
        'etag': '"v1"',
      },
    );
  }

  test('retries only the failed block after a connection cut', () async {
    final requested = <String>[];
    var interrupted = false;
    final client = MockClient.streaming((request, _) async {
      requested.add(request.headers['Range']!);
      if (request.headers['Range'] == 'bytes=8-15' && !interrupted) {
        interrupted = true;
        return http.StreamedResponse(
          Stream<List<int>>.multi((sink) {
            sink.add(data.sublist(8, 10));
            sink.addError(const SocketException('cut'));
            sink.close();
          }),
          206,
          headers: {
            'content-range': 'bytes 8-15/${data.length}',
            'etag': '"v1"',
          },
        );
      }
      return range(request, data);
    });
    await const ResumableDownload(
      chunkSize: 8,
      retryDelay: Duration.zero,
    ).fetch(uri, target, client: client);
    expect(await target.readAsBytes(), data);
    expect(requested.where((r) => r == 'bytes=0-7').length, 1);
    expect(requested.where((r) => r == 'bytes=8-15').length, 2);
  });
  test('resumes persisted blocks after the application restarts', () async {
    await File('${target.path}.part').writeAsBytes(data.sublist(0, 10));
    await File('${target.path}.part.json').writeAsString(
      jsonEncode({
        'resource': uri.toString(),
        'offset': 8,
        'total': data.length,
        'validator': '"v1"',
      }),
    );
    final requests = <http.BaseRequest>[];
    final client = MockClient.streaming((request, _) async {
      requests.add(request);
      return range(request, data);
    });
    await const ResumableDownload(chunkSize: 8)
        .fetch(uri, target, client: client);
    expect(requests.first.headers['Range'], 'bytes=8-15');
    expect(requests.first.headers['If-Range'], '"v1"');
    expect(await target.readAsBytes(), data);
  });
  test(
    '200 replaces a partial file instead of corrupting it by appending',
    () async {
      await File('${target.path}.part').writeAsBytes(data.sublist(0, 8));
      await File('${target.path}.part.json').writeAsString(
        jsonEncode({
          'resource': uri.toString(),
          'offset': 8,
          'total': data.length,
          'validator': '"old"',
        }),
      );
      final client = MockClient.streaming(
        (request, _) async => http.StreamedResponse(
          Stream.value(data),
          200,
          contentLength: data.length,
        ),
      );
      await const ResumableDownload(chunkSize: 8)
          .fetch(uri, target, client: client);
      expect(await target.readAsBytes(), data);
    },
  );
  test(
    'rejects incorrect ranges without publishing an incomplete document',
    () async {
      final client = MockClient.streaming(
        (request, _) async => http.StreamedResponse(
          Stream.value(data.sublist(0, 8)),
          206,
          headers: {'content-range': 'bytes 3-10/${data.length}'},
        ),
      );
      await expectLater(
        const ResumableDownload(chunkSize: 8)
            .fetch(uri, target, client: client),
        throwsA(isA<HttpException>()),
      );
      expect(await target.exists(), false);
    },
  );
  test(
    'keeps complete blocks when all automatic retries are exhausted',
    () async {
      var calls = 0;
      final client = MockClient.streaming((request, _) async {
        calls++;
        if (calls == 1) return range(request, data);
        throw const SocketException('offline');
      });
      await expectLater(
        const ResumableDownload(
          chunkSize: 8,
          retryDelay: Duration.zero,
        ).fetch(uri, target, client: client),
        throwsA(isA<SocketException>()),
      );
      expect(await target.exists(), false);
      expect(
        await File('${target.path}.part').readAsBytes(),
        data.sublist(0, 8),
      );
      expect(calls, 6);
    },
  );
}
