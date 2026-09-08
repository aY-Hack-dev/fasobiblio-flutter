import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdfrx/pdfrx.dart';

import '../core/app_feedback.dart';
import '../services/local_store.dart';

class AudioReaderScreen extends StatefulWidget {
  const AudioReaderScreen({
    super.key,
    required this.path,
    required this.title,
    required this.id,
    this.page = 1,
  });
  final String path, title, id;
  final int page;
  @override
  State<AudioReaderScreen> createState() => _AudioReaderScreenState();
}

class _AudioReaderScreenState extends State<AudioReaderScreen> {
  final tts = FlutterTts();
  final store = LocalStore();
  PdfDocument? document;
  bool ready = false, playing = false, loading = false;
  int page = 1, offset = 0, spoken = 0;
  double rate = .5;
  String text = '', error = '';
  int generation = 0;
  String get key => 'reader.audio.${widget.id}';
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    try {
      await tts.setLanguage('fr-FR');
      await tts.setSpeechRate(rate);
      await tts.awaitSpeakCompletion(true);
      tts.setProgressHandler((
        String utterance,
        int start,
        int end,
        String word,
      ) {
        spoken = start;
      });
      document = await PdfDocument.openFile(widget.path);
      final saved = await store.loadJson(key);
      page = saved is Map
          ? (saved['page'] as int? ?? widget.page)
          : widget.page;
      offset = saved is Map ? (saved['offset'] as int? ?? 0) : 0;
      page = page.clamp(1, document!.pages.length);
      await loadPage();
      if (mounted) setState(() => ready = true);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = friendlyFailure(e, action: 'ouvrir la lecture audio'),
        );
      }
    }
  }

  Future<void> loadPage() async {
    if (document == null) return;
    final value = (await document!.pages[page - 1].loadText())?.fullText ?? '';
    if (!mounted) return;
    setState(() {
      text = value.trim();
      offset = offset.clamp(0, text.length);
    });
  }

  Future<void> save() async =>
      store.saveJson(key, {'page': page, 'offset': offset});
  Future<void> stop() async {
    generation++;
    await tts.stop();
    offset = (offset + spoken).clamp(0, text.length);
    spoken = 0;
    await save();
    if (mounted) setState(() => playing = false);
  }

  Future<void> play() async {
    if (playing) {
      await stop();
      return;
    }
    final run = ++generation;
    setState(() {
      playing = true;
      error = '';
    });
    try {
      while (mounted && run == generation && page <= document!.pages.length) {
        if (text.isEmpty) {
          setState(
            () => error = 'Cette page est scannée ou sans texte. Passez à la suivante ou utilisez l’extraction serveur.',
          );
          break;
        }
        while (offset < text.length && mounted && run == generation) {
          final end = (offset + 2500).clamp(0, text.length);
          spoken = 0;
          await tts.speak(text.substring(offset, end));
          if (run != generation) return;
          offset = end;
          await save();
        }
        if (run != generation || page == document!.pages.length) break;
        page++;
        offset = 0;
        await loadPage();
        await save();
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => error = friendlyFailure(
            e,
            action: 'lire ce document à voix haute',
          ),
        );
      }
    } finally {
      if (mounted && run == generation) setState(() => playing = false);
    }
  }

  Future<void> move(int delta) async {
    await stop();
    if (!mounted) return;
    page = (page + delta).clamp(1, document!.pages.length);
    offset = 0;
    await loadPage();
    await save();
  }

  @override
  void dispose() {
    generation++;
    tts.stop();
    document?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Lecture audio')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.headphones, size: 72),
          const SizedBox(height: 20),
          Text(
            widget.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Page $page / ${document?.pages.length ?? '…'}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!ready && error.isEmpty) const LinearProgressIndicator(),
          if (error.isNotEmpty)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Page précédente',
                onPressed: ready && page > 1 ? () => move(-1) : null,
                icon: const Icon(Icons.skip_previous),
              ),
              FilledButton.icon(
                onPressed: ready ? play : null,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? 'Pause' : 'Écouter'),
              ),
              IconButton(
                tooltip: 'Page suivante',
                onPressed: ready && page < (document?.pages.length ?? 0)
                    ? () => move(1)
                    : null,
                icon: const Icon(Icons.skip_next),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Vitesse · ${(rate / .5).toStringAsFixed(1)}×'),
          Slider(
            value: rate,
            min: .25,
            max: .8,
            divisions: 11,
            onChanged: (value) async {
              await stop();
              await tts.setSpeechRate(value);
              if (mounted) setState(() => rate = value);
            },
          ),
          const Text(
            'La disponibilité hors ligne dépend de la voix française installée sur le téléphone.',
          ),
          const Divider(height: 32),
          SelectableText(text, style: const TextStyle(height: 1.6)),
        ],
      ),
    ),
  );
}
