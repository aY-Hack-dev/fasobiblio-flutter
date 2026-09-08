import 'dart:io';

import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../core/app_feedback.dart';
import 'pdf_reader_screen.dart';
import 'book_detail_screen.dart';

class ReadingActivityScreen extends StatefulWidget {
  const ReadingActivityScreen({
    super.key,
    required this.state,
    this.notes = false,
  });
  final AppState state;
  final bool notes;
  @override
  State<ReadingActivityScreen> createState() => _ReadingActivityScreenState();
}

class _ReadingActivityScreenState extends State<ReadingActivityScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final raw = await widget.state.store.loadJson(
      '${widget.notes ? 'reader.notes' : 'reading.history'}.${widget.state.assistantAccountKey}',
    );
    final values = raw is Map
        ? raw.values
        : raw is List
        ? raw
        : [];
    if (mounted) {
      setState(() {
        items =
            values
                .whereType<Map>()
                .map((v) => Map<String, dynamic>.from(v))
                .toList()
              ..sort(
                (a, b) => ((b['updatedAt'] ?? b['createdAt'] ?? 0) as num)
                    .compareTo((a['updatedAt'] ?? a['createdAt'] ?? 0) as num),
              );
        loading = false;
      });
    }
  }

  Future<void> open(Map<String, dynamic> item) async {
    final path = '${item['path'] ?? ''}';
    if (path.isNotEmpty && await File(path).exists()) {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfReaderScreen(
            path: path,
            title: '${item['title'] ?? 'Document'}',
            documentId: '${item['id']}',
            initialPage: (item['page'] as num?)?.toInt(),
          ),
        ),
      );
    } else {
      final books = widget.state.books.where((b) => b.id == item['id']);
      if (!mounted) return;
      if (books.isEmpty) {
        showToast(
          context,
          'Ce document n’est plus disponible dans le catalogue.',
        );
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              BookDetailScreen(book: books.first, state: widget.state),
        ),
      );
    }
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.notes ? 'Mes notes et passages' : 'Mes lectures'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : items.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                widget.notes
                    ? 'Vos notes prises dans le lecteur apparaîtront ici.'
                    : 'Ouvrez un livre pour commencer votre historique.',
              ),
            ),
          )
        : ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, i) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (_, i) {
              final item = items[i];
              final page = item['page'] ?? 1;
              final total = item['total'] ?? 0;
              return ListTile(
                isThreeLine: widget.notes,
                title: Text(
                  '${item['title'] ?? 'Document'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  widget.notes
                      ? 'Page $page\n${item['text'] ?? ''}'
                      : 'Page $page${total > 0 ? ' / $total' : ''}${total > 0 && page >= total ? ' · Terminé' : ' · En cours'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => open(item),
              );
            },
          ),
  );
}
