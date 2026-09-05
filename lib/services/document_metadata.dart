import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/book.dart';

class DocumentMetadata {
  static Future<Map<String, dynamic>> read(String path) async {
    try { final data = jsonDecode(await File('$path.json').readAsString()); return Map<String,dynamic>.from(data); } catch (_) { return {}; }
  }
  static Future<void> save(String path, Book book) async {
    final file = File('$path.json');
    await file.writeAsString(jsonEncode({'id':book.id,'title':book.title,'image':book.image}), flush:true);
  }
  static Future<void> cover(String path, String image) async {
    if (image.isEmpty || await File('$path.cover').exists()) return;
    final uri = Uri.tryParse(image);
    if (uri == null || uri.scheme != 'https') return;
    final client = http.Client();
    final partial = File('$path.cover.part');
    IOSink? sink;
    try {
      final response = await client.send(http.Request('GET',uri)).timeout(const Duration(seconds:10));
      if(response.statusCode!=200) return;
      sink=partial.openWrite();var size=0;
      await for(final chunk in response.stream.timeout(const Duration(seconds:10))) {
        size+=chunk.length;if(size>5*1024*1024) throw const FormatException('Couverture trop volumineuse');sink.add(chunk);
      }
      await sink.close();sink=null;if(size>0)await partial.rename('$path.cover');
    } catch (_) {} finally { await sink?.close();client.close();if(await partial.exists())await partial.delete(); }
  }
}
