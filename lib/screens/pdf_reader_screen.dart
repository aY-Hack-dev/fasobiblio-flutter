import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../widgets/app_scope.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  bool summarizing = false;

  Future<String> _extractText() async {
    final document = await PdfDocument.openFile(widget.path);
    try {
      final buffer = StringBuffer();
      const maxChars = 18000;
      final pagesToSample = math.min(document.pages.length, 28);
      for (var index = 0; index < pagesToSample; index++) {
        final raw = await document.pages[index].loadText();
        final text = raw?.fullText.trim() ?? '';
        if (text.isEmpty) continue;
        buffer.writeln('\n--- Page ${index + 1} ---\n$text');
        if (buffer.length >= maxChars) break;
      }
      final value = buffer.toString().trim();
      return value.length > maxChars ? value.substring(0, maxChars) : value;
    } finally {
      await document.dispose();
    }
  }

  Future<void> _summarize() async {
    if (summarizing) return;
    final state = AppScope.of(context);
    if (!requireInternet(context, state)) return;
    setState(() => summarizing = true);
    try {
      final extracted = await _extractText();
      if (!mounted) return;
      if (extracted.length < 120) {
        showToast(context, 'Ce PDF semble être scanné ou ne contient pas assez de texte extractible pour générer un résumé.');
        return;
      }
      final prompt = '''
Tu résumes un document actuellement ouvert dans Fasobiblio.
Titre : ${widget.title}

À partir UNIQUEMENT du texte extrait ci-dessous, produis un résumé fiable en français.
- Commence par 1 phrase qui donne l’idée générale.
- Puis donne entre 5 et 10 points clés maximum.
- Termine par « À retenir » avec 2 ou 3 phrases courtes.
- N’invente aucune information absente du texte.
- Si l’extrait est incomplet, signale-le brièvement.

TEXTE EXTRAIT :
$extracted
''';
      final summary = await state.api.assistant(prompt);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SummarySheet(title: widget.title, summary: summary),
      );
    } catch (error) {
      if (mounted) showToast(context, friendlyFailure(error, action: 'résumer ce document'));
    } finally {
      if (mounted) setState(() => summarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1630),
        appBar: AppBar(
          toolbarHeight: 72,
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
                    const Text('LECTURE FASOBIBLIO', style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF87A9ED))),
                    const SizedBox(height: 3),
                    Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 15, weight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filled(
                onPressed: summarizing ? null : _summarize,
                tooltip: 'Résumé IA',
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF1B4ED8), foregroundColor: Colors.white),
                icon: summarizing
                    ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2.1, color: Colors.white))
                    : const Icon(AppIcons.sparkles, size: 19),
              ),
            ),
          ],
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
                  child: PdfViewer.file(widget.path),
                ),
              ),
            ),
          ),
        ),
      );
}

class _SummarySheet extends StatelessWidget {
  const _SummarySheet({required this.title, required this.summary});
  final String title;
  final String summary;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return FractionallySizedBox(
      heightFactor: .86,
      child: Material(
        color: dark ? const Color(0xFF101827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 5, decoration: BoxDecoration(color: dark ? const Color(0xFF43516A) : const Color(0xFFD4DDEA), borderRadius: BorderRadius.circular(10))),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 10, 10),
              child: Row(
                children: [
                  Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(14)), child: const Icon(AppIcons.sparkles, color: AppColors.blueDeep, size: 21)),
                  const SizedBox(width: 11),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Résumé IA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                  ])),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close)),
                ],
              ),
            ),
            Divider(height: 1, color: Theme.of(context).dividerColor.withValues(alpha: .5)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                child: MarkdownBody(
                  data: summary,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.55),
                    h1: Theme.of(context).textTheme.headlineMedium,
                    h2: Theme.of(context).textTheme.titleLarge,
                    h3: Theme.of(context).textTheme.titleMedium,
                    listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
