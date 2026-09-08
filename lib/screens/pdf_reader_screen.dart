import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/app_feedback.dart';
import '../services/local_store.dart';
import '../widgets/app_scope.dart';
import '../widgets/document_cover.dart';
import 'document_assistant_sheet.dart';
import 'audio_reader_screen.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.path,
    required this.title,
    this.documentId,
    this.initialPage,
  });
  final String path, title;
  final String? documentId;
  final int? initialPage;
  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final viewer = PdfViewerController();
  final store = LocalStore();
  late final Future<int> savedPage = _load();
  int currentPage = 1, total = 0;
  String theme = 'system';
  bool fullscreen = false;
  Set<String> bookmarks = {};
  Timer? _saveTimer;
  String get id => widget.documentId ?? widget.path.split('/').last;
  String get pageKey => 'reader.page.$id';
  String get account => AppScope.of(context).assistantAccountKey;
  Future<int> _load() async {
    final page =
        await store.loadJson(pageKey) ??
        await store.loadJson('reader.page.${widget.path.split('/').last}');
    theme = (await store.loadJson('reader.theme')) as String? ?? 'system';
    currentPage = widget.initialPage ?? (page is int && page > 0 ? page : 1);
    return currentPage;
  }

  Future<void> saveProgress() async {
    try {
      await store.saveJson(pageKey, currentPage);
      final old = await store.loadJson('reading.history.$account');
      final history = old is Map
          ? Map<String, dynamic>.from(old)
          : <String, dynamic>{};
      history[id] = {
        'id': id,
        'title': widget.title,
        'path': widget.path,
        'page': currentPage,
        'total': total,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      await store.saveJson('reading.history.$account', history);
    } catch (_) {}
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  Future<void> jump() async {
    final controller = TextEditingController(text: '$currentPage');
    final page = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aller à une page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Page du PDF (1 à $total)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              final p = int.tryParse(controller.text);
              if (p != null && p >= 1 && p <= total) Navigator.pop(context, p);
            },
            child: const Text('Ouvrir'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (page != null && viewer.isReady) await viewer.goToPage(pageNumber: page);
  }

  Future<void> note() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Note · page $currentPage'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          maxLength: 3000,
          decoration: const InputDecoration(
            hintText: 'Votre note ou passage favori',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    final key = 'reader.notes.$account';
    final raw = await store.loadJson(key);
    final notes = raw is List ? List<dynamic>.from(raw) : <dynamic>[];
    notes.add({
      'id': id,
      'title': widget.title,
      'path': widget.path,
      'page': currentPage,
      'text': text,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await store.saveJson(key, notes);
    if (mounted) showToast(context, 'Note enregistrée.', success: true);
  }

  Future<void> search() async {
    if (!viewer.isReady) return;
    final input = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher dans le livre'),
        content: TextField(
          controller: input,
          decoration: const InputDecoration(hintText: 'Mot ou expression'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, input.text.trim()),
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
    input.dispose();
    if (query == null || query.isEmpty || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .7,
        child: _PageSearch(
          document: viewer.document,
          query: query,
          onPage: (page) {
            Navigator.pop(context);
            viewer.goToPage(pageNumber: page);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark =
        theme == 'night' ||
        (theme == 'system' && Theme.of(context).brightness == Brightness.dark);
    final sepia = theme == 'sepia';
    final background = dark
        ? const Color(0xFF111827)
        : sepia
        ? const Color(0xFFF3E7D3)
        : const Color(0xFFF1F4F9);
    final foreground = dark ? Colors.white : const Color(0xFF192339);
    final matches = state.books.where((b) => b.id == widget.documentId);
    final cover = matches.isEmpty ? '' : matches.first.image;
    Widget pdf = FutureBuilder<int>(
      future: savedPage,
      builder: (context, snapshot) => !snapshot.hasData
          ? const Center(child: CircularProgressIndicator())
          : PdfViewer.file(
              widget.path,
              controller: viewer,
              initialPageNumber: snapshot.data!,
              params: PdfViewerParams(
                backgroundColor: dark ? const Color(0xFFEEE7D8) : background,
                onViewerReady: (document, controller) {
                  if (mounted) setState(() => total = document.pages.length);
                },
                onPageChanged: (page) {
                  if (page != null && mounted) {
                    setState(() => currentPage = page);
                    _saveTimer?.cancel();
                    _saveTimer = Timer(
                      const Duration(milliseconds: 350),
                      saveProgress,
                    );
                  }
                },
              ),
            ),
    );
    if (dark) {
      pdf = ColorFiltered(
        colorFilter: const ColorFilter.matrix([
          -1,
          0,
          0,
          0,
          255,
          0,
          -1,
          0,
          0,
          255,
          0,
          0,
          -1,
          0,
          255,
          0,
          0,
          0,
          1,
          0,
        ]),
        child: pdf,
      );
    }
    if (sepia) {
      pdf = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          Color(0xFFF6E8CC),
          BlendMode.modulate,
        ),
        child: pdf,
      );
    }
    return Scaffold(
      backgroundColor: background,
      appBar: fullscreen
          ? null
          : AppBar(
              backgroundColor: background,
              foregroundColor: foreground,
              titleSpacing: 0,
              title: Row(
                children: [
                  if (cover.isNotEmpty) ...[
                    SizedBox(
                      width: 28,
                      height: 40,
                      child: DocumentCover(
                        imageUrl: cover,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Assistant du document',
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => SizedBox(
                      height: MediaQuery.sizeOf(context).height * .88,
                      child: DocumentAssistantSheet(
                        path: widget.path,
                        title: widget.title,
                        id: id,
                        page: currentPage,
                        state: state,
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Outils de lecture',
                  onSelected: (value) async {
                    if (value == 'search') {
                      await search();
                      return;
                    }
                    if (value == 'note') {
                      await note();
                      return;
                    }
                    if (value == 'audio') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AudioReaderScreen(
                            path: widget.path,
                            title: widget.title,
                            id: id,
                            page: currentPage,
                          ),
                        ),
                      );
                      return;
                    }
                    if (value == 'bookmark') {
                      final key = 'reader.bookmarks.$account.$id';
                      final saved = await store.load(key);
                      saved.contains('$currentPage')
                          ? saved.remove('$currentPage')
                          : saved.add('$currentPage');
                      await store.save(key, saved);
                      if (context.mounted) {
                        showToast(
                          context,
                          'Marque-page mis à jour.',
                          success: true,
                        );
                      }
                      return;
                    }
                    setState(() => theme = value);
                    await store.saveJson('reader.theme', value);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'day', child: Text('Mode jour')),
                    PopupMenuItem(value: 'night', child: Text('Mode nuit')),
                    PopupMenuItem(value: 'sepia', child: Text('Mode sépia')),
                    PopupMenuItem(
                      value: 'system',
                      child: Text('Thème de l’application'),
                    ),
                    PopupMenuItem(
                      value: 'search',
                      child: Text('Rechercher dans le livre'),
                    ),
                    PopupMenuItem(
                      value: 'audio',
                      child: Text('Écouter le livre'),
                    ),
                    PopupMenuItem(
                      value: 'bookmark',
                      child: Text('Ajouter / retirer un marque-page'),
                    ),
                    PopupMenuItem(
                      value: 'note',
                      child: Text('Ajouter une note'),
                    ),
                  ],
                ),
              ],
            ),
      body: SafeArea(
        top: fullscreen,
        child: Stack(
          children: [
            Positioned.fill(child: pdf),
            if (fullscreen)
              Positioned(
                right: 12,
                top: 12,
                child: IconButton.filled(
                  tooltip: 'Quitter le plein écran',
                  onPressed: () => setState(() => fullscreen = false),
                  icon: const Icon(Icons.fullscreen_exit),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: fullscreen
          ? null
          : SafeArea(
              top: false,
              child: ColoredBox(
                color: background,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Page précédente',
                      onPressed: viewer.isReady && currentPage > 1
                          ? () => viewer.goToPage(pageNumber: currentPage - 1)
                          : null,
                      icon: Icon(Icons.chevron_left, color: foreground),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: total > 0 ? jump : null,
                        child: Text(
                          '$currentPage / ${total == 0 ? '…' : total}',
                          style: TextStyle(color: foreground),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Page suivante',
                      onPressed: viewer.isReady && currentPage < total
                          ? () => viewer.goToPage(pageNumber: currentPage + 1)
                          : null,
                      icon: Icon(Icons.chevron_right, color: foreground),
                    ),
                    IconButton(
                      tooltip: 'Ajuster la page',
                      onPressed: viewer.isReady
                          ? () => viewer.goTo(
                              viewer.calcMatrixForFit(pageNumber: currentPage),
                            )
                          : null,
                      icon: Icon(Icons.fit_screen, color: foreground),
                    ),
                    IconButton(
                      tooltip: 'Plein écran',
                      onPressed: () => setState(() => fullscreen = true),
                      icon: Icon(Icons.fullscreen, color: foreground),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _PageSearch extends StatefulWidget {
  const _PageSearch({
    required this.document,
    required this.query,
    required this.onPage,
  });
  final PdfDocument document;
  final String query;
  final ValueChanged<int> onPage;
  @override
  State<_PageSearch> createState() => _PageSearchState();
}

class _PageSearchState extends State<_PageSearch> {
  final hits = <(int, String)>[];
  bool busy = true;
  int scanned = 0;
  @override
  void initState() {
    super.initState();
    run();
  }

  Future<void> run() async {
    try {
      for (final page in widget.document.pages) {
        if (!mounted) return;
        final text = (await page.loadText())?.fullText ?? '';
        if (!mounted) return;
        final index = text.toLowerCase().indexOf(widget.query.toLowerCase());
        setState(() {
          scanned++;
          if (index >= 0) {
            hits.add((
              page.pageNumber,
              text
                  .substring(
                    (index - 60).clamp(0, text.length),
                    (index + 180).clamp(0, text.length),
                  )
                  .replaceAll('\n', ' '),
            ));
          }
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'Résultats · ${widget.query}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      if (busy)
        LinearProgressIndicator(value: scanned / widget.document.pages.length),
      if (!busy && hits.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Aucun résultat dans le texte extractible. Les pages scannées nécessitent une reconnaissance du texte.',
          ),
        ),
      Expanded(
        child: ListView.builder(
          itemCount: hits.length,
          itemBuilder: (_, i) => ListTile(
            title: Text('Page ${hits[i].$1}'),
            subtitle: Text(hits[i].$2),
            onTap: () => widget.onPage(hits[i].$1),
          ),
        ),
      ),
    ],
  );
}
