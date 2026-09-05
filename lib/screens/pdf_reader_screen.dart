import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme.dart';
import '../services/local_store.dart';
import '../widgets/app_scope.dart';
import '../core/app_feedback.dart';
import 'assistant_screen.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}
class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final viewer = PdfViewerController();
  late final Future<int> savedPage = _loadPage();
  int currentPage = 1;
  bool extracting = false;
  String get path => widget.path;
  String get title => widget.title;
  String get pageKey => 'reader.page.${path.split('/').last}';
  Future<int> _loadPage() async {
    final value = await LocalStore().loadJson(pageKey);
    return value is int && value > 0 ? value : 1;
  }
  Future<void> documentAssistant() async {
    if (extracting || !viewer.isReady) return;
    setState(() => extracting = true);
    try {
      final doc = viewer.document;
      final buffer = StringBuffer();
      // Limit extraction to the current page and neighbours on modest devices.
      for (var number = currentPage > 1 ? currentPage - 1 : 1; number <= currentPage + 1 && number <= doc.pages.length; number++) {
        final text = (await doc.pages[number - 1].loadText())?.fullText ?? '';
        if (text.trim().isNotEmpty) buffer.writeln('Page $number:\n${text.length > 5000 ? text.substring(0, 5000) : text}');
      }
      if (!mounted) return;
      if (buffer.isEmpty) { showToast(context, 'Ce PDF ne contient pas de texte extractible sur ces pages.'); return; }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(
        state: AppScope.of(context), documentTitle: title, documentContext: buffer.toString())));
    } catch (e) { if (mounted) showToast(context, friendlyFailure(e, action: 'préparer cet extrait')); }
    finally { if (mounted) setState(() => extracting = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1630),
        appBar: AppBar(
          toolbarHeight: 72,
          actions: [IconButton(tooltip: 'Interroger ces pages', onPressed: extracting ? null : documentAssistant, icon: const Icon(AppIcons.sparkles))],
          backgroundColor: const Color(0xFF0B1630),
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(AppIcons.bookOpen, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LECTURE FASOBIBLIO', style: TextStyle(fontSize:12, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF87A9ED))),
                    const SizedBox(height: 3),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 15, weight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0B1630), Color(0xFF111C35)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFF20242C)),
                  child: FutureBuilder<int>(future: savedPage, builder: (context, snapshot) => !snapshot.hasData ? const Center(child: CircularProgressIndicator()) : PdfViewer.file(path, controller: viewer, initialPageNumber: snapshot.data!, params: PdfViewerParams(onPageChanged: (page) { if (page != null) { currentPage = page; LocalStore().saveJson(pageKey, page).catchError((_) {}); } }))),
                ),
              ),
            ),
          ),
        ),
      );
}
