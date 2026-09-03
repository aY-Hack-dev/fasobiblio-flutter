import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({
    super.key,
    required this.path,
    required this.title,
    this.state,
    this.documentId,
  });

  final String path;
  final String title;
  final AppState? state;
  final String? documentId;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

enum _ReadingMode { light, comfort, dark }

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final controller = PdfViewerController();
  late final PdfTextSearcher searcher;
  final tts = FlutterTts();
  final searchController = TextEditingController();

  int page = 1;
  int pageCount = 0;
  List<PdfOutlineNode> outline = const [];
  bool controlsVisible = true;
  bool speaking = false;
  bool paused = false;
  bool autoContinueAudio = true;
  double speechRate = .46;
  _ReadingMode mode = _ReadingMode.light;

  String get id => widget.documentId ?? '';
  bool get bookmarked => id.isNotEmpty && (widget.state?.readingBookmarks(id).contains(page) ?? false);

  @override
  void initState() {
    super.initState();
    page = id.isEmpty ? 1 : (widget.state?.readingPage(id) ?? 1);
    searcher = PdfTextSearcher(controller)..addListener(_searchChanged);
    tts.setLanguage('fr-FR');
    tts.setSpeechRate(speechRate);
    tts.setVolume(1);
    tts.setPitch(1);
    tts.awaitSpeakCompletion(true);
    tts.setStartHandler(() {
      if (mounted) setState(() { speaking = true; paused = false; });
    });
    tts.setPauseHandler(() {
      if (mounted) setState(() { speaking = false; paused = true; });
    });
    tts.setContinueHandler(() {
      if (mounted) setState(() { speaking = true; paused = false; });
    });
    tts.setCompletionHandler(() => unawaited(_afterSpeech()));
    tts.setCancelHandler((_) {
      if (mounted) setState(() { speaking = false; paused = false; });
    });
    tts.setErrorHandler((_) {
      if (mounted) setState(() { speaking = false; paused = false; });
    });
  }

  void _searchChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    unawaited(tts.stop());
    searcher.removeListener(_searchChanged);
    searcher.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _savePage(int value) async {
    if (value <= 0) return;
    setState(() => page = value);
    if (id.isNotEmpty && widget.state != null) {
      await widget.state!.saveReadingPosition(id, value, pageCount, title: widget.title);
    }
  }

  Future<String> _currentPageText() async {
    if (!controller.isReady || page < 1 || page > controller.pages.length) return '';
    final raw = await controller.pages[page - 1].loadText();
    return raw?.fullText.trim() ?? '';
  }

  Future<void> _speakCurrentPage() async {
    final text = await _currentPageText();
    if (!mounted) return;
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucun texte lisible sur cette page. Ce PDF est peut-être une image scannée.')));
      setState(() { speaking = false; paused = false; });
      return;
    }
    await tts.stop();
    await tts.setSpeechRate(speechRate);
    final maxLength = await tts.getMaxSpeechInputLength;
    final limit = maxLength is int && maxLength > 100 ? maxLength : 3500;
    final safeText = text.length > limit ? text.substring(0, limit) : text;
    await tts.speak(safeText);
  }

  Future<void> _toggleAudio() async {
    if (speaking) {
      await tts.pause();
      return;
    }
    if (paused) {
      final result = await tts.speak(await _currentPageText());
      if (result == 1 && mounted) setState(() { speaking = true; paused = false; });
      return;
    }
    await _speakCurrentPage();
  }

  Future<void> _afterSpeech() async {
    if (!mounted) return;
    setState(() { speaking = false; paused = false; });
    if (!autoContinueAudio || page >= pageCount || !controller.isReady) return;
    final next = page + 1;
    await controller.goToPage(pageNumber: next);
    await _savePage(next);
    await _speakCurrentPage();
  }

  Future<void> _stopAudio() async {
    await tts.stop();
    if (mounted) setState(() { speaking = false; paused = false; });
  }

  Future<void> _toggleBookmark() async {
    if (id.isEmpty || widget.state == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Les signets sont disponibles pour les documents ouverts depuis Fasobiblio.')));
      return;
    }
    await widget.state!.toggleReadingBookmark(id, page);
    if (mounted) setState(() {});
  }

  Future<void> _showSearch() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, update) {
        return Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, MediaQuery.viewInsetsOf(context).bottom + 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const Icon(Icons.search_rounded),
              const SizedBox(width: 10),
              Expanded(child: Text('Rechercher dans le document', style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: searchController,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(hintText: 'Mot ou expression…'),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;
                searcher.startTextSearch(value.trim(), searchImmediately: true);
                update(() {});
              },
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Text(searcher.isSearching
                  ? 'Recherche en cours…'
                  : searcher.matches.isEmpty
                      ? 'Saisissez un terme puis lancez la recherche.'
                      : '${searcher.matches.length} résultat(s)', style: const TextStyle(fontSize: 12, color: AppColors.muted))),
              IconButton(onPressed: searcher.hasMatches ? () async { await searcher.goToPrevMatch(); update(() {}); } : null, icon: const Icon(Icons.keyboard_arrow_up_rounded)),
              IconButton(onPressed: searcher.hasMatches ? () async { await searcher.goToNextMatch(); update(() {}); } : null, icon: const Icon(Icons.keyboard_arrow_down_rounded)),
            ]),
          ]),
        );
      }),
    );
  }

  Future<void> _showOutline() async {
    if (outline.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ce document ne contient pas de sommaire intégré.')));
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .68,
        maxChildSize: .92,
        builder: (_, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
          children: [
            Padding(padding: const EdgeInsets.all(10), child: Text('Sommaire', style: Theme.of(context).textTheme.titleLarge)),
            ..._outlineTiles(outline, context),
          ],
        ),
      ),
    );
  }

  List<Widget> _outlineTiles(List<PdfOutlineNode> nodes, BuildContext sheetContext, [int depth = 0]) {
    return nodes.expand((node) sync* {
      yield ListTile(
        contentPadding: EdgeInsets.only(left: 10.0 + depth * 16, right: 8),
        dense: true,
        title: Text(node.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right_rounded, size: 18),
        onTap: node.dest == null ? null : () async {
          Navigator.pop(sheetContext);
          await controller.goToDest(node.dest);
        },
      );
      if (node.children.isNotEmpty) yield* _outlineTiles(node.children, sheetContext, depth + 1);
    }).toList();
  }

  Future<void> _showReaderSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(builder: (context, update) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Confort de lecture', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SegmentedButton<_ReadingMode>(
            segments: const [
              ButtonSegment(value: _ReadingMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Clair')),
              ButtonSegment(value: _ReadingMode.comfort, icon: Icon(Icons.local_cafe_outlined), label: Text('Confort')),
              ButtonSegment(value: _ReadingMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Sombre')),
            ],
            selected: {mode},
            onSelectionChanged: (value) { setState(() => mode = value.first); update(() {}); },
          ),
          const SizedBox(height: 20),
          Row(children: [const Icon(Icons.speed_rounded, size: 20), const SizedBox(width: 9), Text('Vitesse audio ×${(speechRate * 2).toStringAsFixed(1)}')]),
          Slider(
            min: .25,
            max: .85,
            value: speechRate,
            onChanged: (value) { setState(() => speechRate = value); update(() {}); unawaited(tts.setSpeechRate(value)); },
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Continuer automatiquement à la page suivante'),
            value: autoContinueAudio,
            onChanged: (value) { setState(() => autoContinueAudio = value); update(() {}); },
          ),
        ]),
      )),
    );
  }

  Widget _filteredViewer() {
    final viewer = PdfViewer.file(
      widget.path,
      controller: controller,
      initialPageNumber: page,
      params: PdfViewerParams(
        margin: 10,
        backgroundColor: mode == _ReadingMode.dark ? const Color(0xFF0A1020) : mode == _ReadingMode.comfort ? const Color(0xFFE9DFC9) : const Color(0xFFE9EDF5),
        pageDropShadow: const BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4)),
        matchTextColor: const Color(0x80FFD54F),
        activeMatchTextColor: const Color(0xB3FFB300),
        pagePaintCallbacks: [searcher.pageTextMatchPaintCallback],
        onPageChanged: (value) {
          if (value != null) unawaited(_savePage(value));
        },
        onViewerReady: (document, _) async {
          final loadedOutline = await document.loadOutline();
          if (!mounted) return;
          setState(() {
            outline = loadedOutline;
            pageCount = controller.pageCount;
          });
          if (id.isNotEmpty && widget.state != null) {
            await widget.state!.saveReadingPosition(id, page, pageCount, title: widget.title);
          }
        },
        onGeneralTap: (_) {
          setState(() => controlsVisible = !controlsVisible);
          return true;
        },
      ),
    );

    if (mode == _ReadingMode.dark) {
      return ColorFiltered(colorFilter: const ColorFilter.mode(Colors.white, BlendMode.difference), child: viewer);
    }
    if (mode == _ReadingMode.comfort) {
      return ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          .92, .06, .02, 0, 12,
          .05, .90, .02, 0, 8,
          .02, .05, .78, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: viewer,
      );
    }
    return viewer;
  }

  @override
  Widget build(BuildContext context) {
    final progress = pageCount <= 0 ? 0.0 : (page / pageCount).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: const Color(0xFF07142B),
      body: SafeArea(
        child: Stack(children: [
          Positioned.fill(child: _filteredViewer()),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            left: 10,
            right: 10,
            top: controlsVisible ? 8 : -92,
            child: _ReaderTopBar(
              title: widget.title,
              page: page,
              pageCount: pageCount,
              bookmarked: bookmarked,
              onBack: () => Navigator.pop(context),
              onBookmark: _toggleBookmark,
              onSearch: _showSearch,
              onOutline: _showOutline,
              onSettings: _showReaderSettings,
            ),
          ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 180),
            left: 10,
            right: 10,
            bottom: controlsVisible ? 10 : -128,
            child: _ReaderBottomBar(
              page: page,
              pageCount: pageCount,
              progress: progress,
              speaking: speaking,
              paused: paused,
              onAudio: _toggleAudio,
              onStop: _stopAudio,
              onPrevious: page > 1 ? () => controller.goToPage(pageNumber: page - 1) : null,
              onNext: pageCount > 0 && page < pageCount ? () => controller.goToPage(pageNumber: page + 1) : null,
            ),
          ),
        ]),
      ),
    );
  }
}

class _ReaderTopBar extends StatelessWidget {
  const _ReaderTopBar({required this.title, required this.page, required this.pageCount, required this.bookmarked, required this.onBack, required this.onBookmark, required this.onSearch, required this.onOutline, required this.onSettings});
  final String title;
  final int page;
  final int pageCount;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSearch;
  final VoidCallback onOutline;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xF20A1730),
    borderRadius: BorderRadius.circular(22),
    elevation: 10,
    shadowColor: Colors.black38,
    child: SizedBox(
      height: 72,
      child: Row(children: [
        IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back_rounded, color: Colors.white)),
        Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 14, weight: FontWeight.w800, color: Colors.white)),
          const SizedBox(height: 3),
          Text(pageCount > 0 ? 'Page $page sur $pageCount' : 'Préparation…', style: const TextStyle(fontSize: 10, color: Color(0xFFAFC5F1))),
        ])),
        IconButton(onPressed: onSearch, tooltip: 'Rechercher', icon: const Icon(Icons.search_rounded, color: Colors.white)),
        IconButton(onPressed: onOutline, tooltip: 'Sommaire', icon: const Icon(Icons.format_list_bulleted_rounded, color: Colors.white)),
        IconButton(onPressed: onBookmark, tooltip: 'Signet', icon: Icon(bookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, color: bookmarked ? const Color(0xFFFFCC66) : Colors.white)),
        IconButton(onPressed: onSettings, tooltip: 'Confort', icon: const Icon(Icons.tune_rounded, color: Colors.white)),
      ]),
    ),
  );
}

class _ReaderBottomBar extends StatelessWidget {
  const _ReaderBottomBar({required this.page, required this.pageCount, required this.progress, required this.speaking, required this.paused, required this.onAudio, required this.onStop, required this.onPrevious, required this.onNext});
  final int page;
  final int pageCount;
  final double progress;
  final bool speaking;
  final bool paused;
  final VoidCallback onAudio;
  final VoidCallback onStop;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xF20A1730),
    elevation: 14,
    shadowColor: Colors.black45,
    borderRadius: BorderRadius.circular(25),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFAFC5F1))),
          const SizedBox(width: 10),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 4, backgroundColor: const Color(0xFF263A61), color: const Color(0xFF6D9CFF)))),
          const SizedBox(width: 10),
          Text('$page/$pageCount', style: const TextStyle(fontSize: 10, color: Color(0xFFAFC5F1))),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          IconButton(onPressed: onPrevious, icon: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 29)),
          FilledButton.icon(
            onPressed: onAudio,
            style: FilledButton.styleFrom(backgroundColor: AppColors.blue, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99))),
            icon: Icon(speaking ? Icons.pause_rounded : Icons.headphones_rounded),
            label: Text(speaking ? 'Pause' : paused ? 'Reprendre' : 'Écouter'),
          ),
          if (speaking || paused) IconButton(onPressed: onStop, tooltip: 'Arrêter', icon: const Icon(Icons.stop_circle_outlined, color: Colors.white))
          else const SizedBox(width: 48),
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 29)),
        ]),
      ]),
    ),
  );
}
