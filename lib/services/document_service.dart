import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentService {
  static const allowedHosts = {'fasobiblio-api.onrender.com', 'fasobiblio.com', 'www.fasobiblio.com', 'repzbcmqtpjnqdbvlvgt.supabase.co'};

  Uri validate(String raw) {
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'https' || !allowedHosts.contains(uri.host.toLowerCase())) throw Exception('Adresse du document non autorisée.');
    return uri;
  }

  Future<void> read(String raw) async {
    final uri = validate(raw);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) throw Exception('Impossible d’ouvrir ce document.');
  }

  Future<String> download(String raw, String name, {void Function(double)? onProgress}) async {
    final uri = validate(raw);
    final request = http.Request('GET', uri);
    final response = await request.send();
    if (response.statusCode < 200 || response.statusCode >= 300) throw Exception('Téléchargement impossible (${response.statusCode}).');
    final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9À-ÿ._ -]'), '_');
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/${safe.toLowerCase().endsWith('.pdf') ? safe : '$safe.pdf'}');
    final sink = file.openWrite();
    var received = 0;
    await for (final chunk in response.stream) {
      received += chunk.length;
      sink.add(chunk);
      if (response.contentLength != null && response.contentLength! > 0) onProgress?.call(received / response.contentLength!);
    }
    await sink.close();
    await OpenFilex.open(file.path);
    return file.path;
  }
}
