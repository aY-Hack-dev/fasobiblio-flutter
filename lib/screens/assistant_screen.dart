import 'dart:async';

import 'dart:io';

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:pdfrx/pdfrx.dart';

import '../models/book.dart';
import '../services/catalog_search.dart';
import '../services/document_service.dart';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({
    super.key,
    required this.state,
    this.documentContext,
    this.documentTitle,
    this.documentId,
  });
  final AppState state;
  final String? documentContext, documentTitle, documentId;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
  Map<String, dynamic> toJson() => {'text': text, 'fromUser': fromUser};
}

class _AssistantScreenState extends State<AssistantScreen>
    with WidgetsBindingObserver {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <_ChatMessage>[];
  bool busy = false, restoring = true;
  Book? selectedBook;
  String? selectedContext;
  final recorder = AudioRecorder();
  final voice = FlutterTts();
  bool voiceMode = false, listening = false, speaking = false;
  bool conversation = false, startingVoice = false, transcribing = false;
  int voiceGeneration = 0;
  Timer? listenAgain, recordingLimit;
  StreamSubscription<Amplitude>? amplitude;
  String? voiceError, recordingPath;
  String dictatedPrefix = '';

  Future<void> stopConversation() async {
    voiceGeneration++;
    listenAgain?.cancel();
    recordingLimit?.cancel();
    await amplitude?.cancel();
    amplitude = null;
    if (mounted)
      setState(() {
        conversation = false;
        listening = false;
        speaking = false;
        transcribing = false;
      });
    await recorder.cancel();
    await voice.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(stopConversation());
    }
  }

  void restartListening() {
    listenAgain?.cancel();
    if (!mounted || !conversation) return;
    listenAgain = Timer(const Duration(milliseconds: 600), () {
      if (mounted &&
          conversation &&
          !busy &&
          !speaking &&
          !listening &&
          !startingVoice &&
          !transcribing) {
        unawaited(listen());
      }
    });
  }

  Future<void> listen() async {
    if (startingVoice || busy || transcribing) return;
    if (listening) {
      await finishRecording();
      return;
    }
    if (!requireInternet(context, widget.state)) return;
    final generation = ++voiceGeneration;
    setState(() {
      startingVoice = true;
      voiceError = null;
    });
    try {
      await voice.stop();
      if (!await recorder.hasPermission()) {
        throw const UserMessage(
          'Autorisez le microphone dans les paramètres de Fasobiblio pour enregistrer votre message.',
        );
      }
      if (!mounted || generation != voiceGeneration) return;
      final root = await getTemporaryDirectory();
      if (!mounted || generation != voiceGeneration) return;
      final previous = recordingPath;
      if (previous != null && await File(previous).exists())
        await File(previous).delete();
      recordingPath =
          '${root.path}/fasobiblio-voice-${DateTime.now().microsecondsSinceEpoch}.m4a';
      dictatedPrefix = conversation ? '' : controller.text.trim();
      await recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 32000,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: recordingPath!,
      );
      if (!mounted || generation != voiceGeneration) {
        await recorder.cancel();
        return;
      }
      setState(() {
        listening = true;
        speaking = false;
      });
      recordingLimit = Timer(
        const Duration(seconds: 90),
        () => unawaited(finishRecording()),
      );
      if (conversation) {
        DateTime? lastSpeech;
        amplitude = recorder
            .onAmplitudeChanged(const Duration(milliseconds: 200))
            .listen((value) {
              if (!mounted || !listening || generation != voiceGeneration)
                return;
              if (value.current > -38) lastSpeech = DateTime.now();
              if (lastSpeech != null &&
                  DateTime.now().difference(lastSpeech!).inMilliseconds >
                      2400) {
                unawaited(finishRecording());
              }
            });
      }
    } catch (error) {
      if (mounted && generation == voiceGeneration)
        setState(() {
          listening = false;
          conversation = false;
          voiceError = friendlyFailure(
            error,
            action: 'enregistrer votre message',
          );
        });
    } finally {
      if (mounted) setState(() => startingVoice = false);
    }
  }

  Future<void> finishRecording() async {
    if (!listening || transcribing) return;
    final generation = voiceGeneration;
    setState(() {
      listening = false;
      transcribing = true;
    });
    recordingLimit?.cancel();
    await amplitude?.cancel();
    amplitude = null;
    try {
      final path = await recorder.stop();
      if (path == null)
        throw const UserMessage('Aucun enregistrement disponible. Réessayez.');
      recordingPath = path;
      await transcribe(generation);
    } catch (error) {
      if (mounted && generation == voiceGeneration)
        setState(() {
          conversation = false;
          voiceError = friendlyFailure(
            error,
            action: 'transcrire votre message',
          );
        });
    } finally {
      if (mounted && generation == voiceGeneration)
        setState(() => transcribing = false);
    }
  }

  Future<void> transcribe(int generation) async {
    final path = recordingPath;
    if (path == null) return;
    final file = File(path);
    final bytes = await file.readAsBytes();
    if (bytes.length > 512 * 1024)
      throw const UserMessage(
        'Cet enregistrement est trop long. Enregistrez un message plus court.',
      );
    final text = await widget.state.api.transcribeAudio(bytes);
    if (!mounted || generation != voiceGeneration) return;
    controller.text = [
      if (dictatedPrefix.isNotEmpty) dictatedPrefix,
      text,
    ].join(' ');
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
    await file.delete();
    recordingPath = null;
    setState(() {
      transcribing = false;
      voiceError = null;
    });
    if (conversation) await ask();
  }

  Future<void> retryTranscription() async {
    if (transcribing || recordingPath == null) return;
    setState(() {
      transcribing = true;
      voiceError = null;
    });
    final generation = voiceGeneration;
    try {
      await transcribe(generation);
    } catch (error) {
      if (mounted && generation == voiceGeneration)
        setState(
          () => voiceError = friendlyFailure(
            error,
            action: 'transcrire votre message',
          ),
        );
    } finally {
      if (mounted && generation == voiceGeneration)
        setState(() => transcribing = false);
    }
  }

  Future<void> speak(String answer) async {
    final generation = voiceGeneration;
    try {
      await voice.setLanguage('fr-FR');
      await voice.setSpeechRate(.5);
      await voice.awaitSpeakCompletion(true);
      if (!mounted ||
          generation != voiceGeneration ||
          (!voiceMode && !conversation))
        return;
      setState(() => speaking = true);
      final plain = answer
          .replaceAll(
            RegExp(r'```[\s\S]*?```'),
            'Exemple de code affiché à l’écran.',
          )
          .replaceAll(RegExp(r'[#*_`|]'), ' ');
      final result = await voice.speak(plain);
      if (result == 0)
        throw const UserMessage(
          'La lecture vocale est indisponible. Activez une voix française dans les paramètres du téléphone.',
        );
    } catch (error) {
      if (mounted && generation == voiceGeneration)
        setState(() {
          conversation = false;
          voiceError = friendlyFailure(
            error,
            action: 'lire la réponse à voix haute',
          );
        });
    } finally {
      if (mounted && generation == voiceGeneration)
        setState(() => speaking = false);
    }
  }

  String get memoryKey =>
      '${widget.state.assistantAccountKey}.${widget.documentId ?? widget.documentTitle ?? 'general'}';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _restore();
  }

  Future<void> _restore() async {
    try {
      var saved = await widget.state.store.loadAssistantMemory(memoryKey);
      if (saved.isEmpty && widget.documentTitle == null) {
        saved = await widget.state.store.loadAssistantMemory(
          widget.state.assistantAccountKey,
        );
      }
      if (!mounted) return;
      setState(() {
        messages.addAll(
          saved
              .map(
                (e) => _ChatMessage(
                  '${e['text'] ?? ''}',
                  fromUser: e['fromUser'] == true,
                ),
              )
              .where((e) => e.text.isNotEmpty),
        );
        restoring = false;
      });
      _scrollDown();
    } catch (_) {
      if (mounted) setState(() => restoring = false);
    }
  }

  Future<void> _persist() => widget.state.store.saveAssistantMemory(
    memoryKey,
    messages.map((e) => e.toJson()).toList(),
  );
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    voiceGeneration++;
    listenAgain?.cancel();
    recordingLimit?.cancel();
    amplitude?.cancel();
    recorder.cancel().then((_) => recorder.dispose());
    final path = recordingPath;
    if (path != null) {
      unawaited(
        File(path).exists().then((exists) async {
          if (exists) await File(path).delete();
        }),
      );
    }
    voice.stop().catchError((Object _) => null);
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> ask() async {
    final question = controller.text.trim();
    if (question.isEmpty || busy || listening || transcribing || startingVoice)
      return;
    if (!requireInternet(context, widget.state)) {
      await stopConversation();
      return;
    }
    voiceGeneration++;
    setState(() => busy = true);
    await recorder.cancel();
    if (!mounted) return;
    setState(() => listening = false);
    controller.clear();
    setState(() {
      messages.add(_ChatMessage(question, fromUser: true));
      busy = true;
      if (messages.length > 80) messages.removeRange(0, messages.length - 80);
    });
    _scrollDown();
    try {
      await _persist();
      final answer = await widget.state.api.assistant(
        question,
        documentContext: await _contextFor(question),
        history: messages
            .take(messages.length - 1)
            .map(
              (m) => {
                'role': m.fromUser ? 'user' : 'assistant',
                'content': m.text,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() => messages.add(_ChatMessage(answer, fromUser: false)));
      if (voiceMode || conversation) await speak(answer);
      await _persist();
    } catch (error) {
      if (mounted) {
        showToast(
          context,
          friendlyFailure(error, action: 'obtenir une réponse de l’assistant'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
      restartListening();
      _scrollDown();
    }
  }

  Future<String?> _contextFor(String question) async {
    final hits = searchCatalog(widget.state.books, question);
    Book? book = selectedBook;
    if (hits.isNotEmpty) {
      if (hits.length == 1 || hits.first.score - hits[1].score > .2) {
        book = hits.first.book;
      } else {
        if (!mounted) return null;
        book = await showDialog<Book>(
          context: context,
          builder: (context) => SimpleDialog(
            title: const Text('Quel document voulez-vous consulter ?'),
            children: hits
                .map(
                  (hit) => SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, hit.book),
                    child: Text('${hit.book.title} — ${hit.book.author}'),
                  ),
                )
                .toList(),
          ),
        );
        if (book == null) {
          throw UserMessage('Choisissez un document pour continuer.');
        }
      }
    }
    if (book == null && widget.documentId != null) {
      final matching = widget.state.books.where(
        (b) => b.id == widget.documentId,
      );
      if (matching.isNotEmpty) book = matching.first;
    }
    final match = RegExp(
      r'pages?\s*(?:n[°o]\s*)?(\d+)',
      caseSensitive: false,
    ).firstMatch(question);
    if (book == null) {
      if (match != null) {
        throw UserMessage('Précisez le titre du document à consulter.');
      }
      return selectedContext ?? widget.documentContext;
    }
    final changed = selectedBook?.id != book.id;
    selectedBook = book;
    if (changed) selectedContext = null;
    if (match == null) {
      return selectedContext ??
          (book.id == widget.documentId ? widget.documentContext : null) ??
          'Document trouvé dans le catalogue : ${book.title}, de ${book.author}. Description : ${book.description}. Le contenu du livre n’est pas encore extrait. Pour expliquer un passage, demande le numéro de page. Ne prétends pas avoir lu le livre.';
    }
    final page = int.parse(match.group(1)!);
    final documents = DocumentService();
    // Check current server access even when a downloaded copy exists.
    final file = await widget.state.api.documentFile(book.id, 'read');
    final path = await documents.ensureLocal(
      file['url']!,
      '${book.id}-${book.title}',
    );
    final pdf = await PdfDocument.openFile(path);
    try {
      if (page < 1 || page > pdf.pages.length) {
        throw UserMessage('Ce document contient ${pdf.pages.length} pages.');
      }
      final extracted =
          (await pdf.pages[page - 1].loadText())?.fullText.trim() ?? '';
      if (extracted.isEmpty) {
        throw UserMessage(
          'Cette page est scannée : son texte doit être reconnu avant de pouvoir l’expliquer.',
        );
      }
      selectedContext =
          'Source : ${book.title}, ${book.author}. Page $page du fichier PDF (la pagination imprimée peut différer). Explique uniquement le texte suivant et indique la source.\n${extracted.length > 27000 ? extracted.substring(0, 27000) : extracted}';
      return selectedContext;
    } finally {
      await pdf.dispose();
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scrollController.hasClients) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    }
  });
  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: conversation
                ? 'Arrêter la conversation vocale'
                : 'Démarrer une conversation vocale',
            onPressed: conversation
                ? stopConversation
                : (busy || startingVoice || listening || transcribing)
                ? null
                : () async {
                    setState(() => conversation = true);
                    await listen();
                  },
            icon: Icon(conversation ? Icons.stop_circle : Icons.headset_mic),
          ),
          IconButton(
            tooltip: voiceMode
                ? 'Désactiver les réponses vocales'
                : 'Activer les réponses vocales',
            onPressed: () {
              setState(() => voiceMode = !voiceMode);
              if (!voiceMode) {
                if (conversation) {
                  unawaited(stopConversation());
                } else {
                  unawaited(voice.stop());
                }
              }
            },
            icon: Icon(voiceMode ? Icons.volume_up : Icons.volume_off),
          ),
        ],
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.blue,
              foregroundColor: Colors.white,
              child: Icon(AppIcons.bot, size: 21),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistant Fasobiblio',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 4,
                        backgroundColor: Color(0xFF22C55E),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Assistant bibliothèque',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.documentTitle != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Questions sur les pages ouvertes : ${widget.documentTitle}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          Expanded(
            child: restoring
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                ? const _Welcome()
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    itemCount: messages.length + (busy ? 1 : 0),
                    itemBuilder: (context, index) => index == messages.length
                        ? const _TypingBubble()
                        : _MessageBubble(message: messages[index]),
                  ),
          ),
          if (conversation ||
              transcribing ||
              listening ||
              startingVoice ||
              speaking ||
              voiceError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      voiceError ??
                          (transcribing
                              ? 'Transcription du message…'
                              : startingVoice
                              ? 'Préparation du microphone…'
                              : listening
                              ? (conversation
                                    ? 'Je vous écoute…'
                                    : 'Dictée en cours… Arrêtez pour relire avant l’envoi.')
                              : speaking
                              ? 'L’assistant vous répond…'
                              : busy
                              ? 'Préparation de la réponse…'
                              : 'Conversation vocale active'),
                      style: TextStyle(
                        color: voiceError != null
                            ? Theme.of(context).colorScheme.error
                            : AppColors.muted,
                      ),
                    ),
                  ),
                  if (voiceError != null &&
                      recordingPath != null &&
                      !transcribing)
                    TextButton(
                      onPressed: retryTranscription,
                      child: const Text('Réessayer'),
                    ),
                  if (conversation || listening)
                    TextButton(
                      onPressed: stopConversation,
                      child: Text(
                        listening && !conversation ? 'Annuler' : 'Arrêter',
                      ),
                    ),
                ],
              ),
            ),
          Container(
            color: surface,
            padding: EdgeInsets.fromLTRB(
              12,
              10,
              12,
              MediaQuery.paddingOf(context).bottom + 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: listening
                          ? 'Je vous écoute…'
                          : 'Posez votre question…',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                IconButton(
                  onPressed: busy || startingVoice || transcribing
                      ? null
                      : listen,
                  tooltip: speaking
                      ? 'Interrompre et parler'
                      : listening
                      ? 'Terminer la dictée'
                      : 'Dicter un message',
                  icon: Icon(listening ? Icons.mic : Icons.mic_none),
                ),
                IconButton.filled(
                  onPressed: busy || listening || startingVoice || transcribing
                      ? null
                      : ask,
                  icon: const Icon(AppIcons.send),
                  tooltip: 'Envoyer',
                  style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome();
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(28, 48, 28, 20),
    children: [
      Center(
        child: Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.ink, AppColors.blue],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(AppIcons.bot, color: Colors.white, size: 31),
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Votre assistant de lecture',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      const Text(
        'Je vous aide à trouver des documents dans le catalogue Fasobiblio, à choisir vos prochaines lectures et à comprendre le fonctionnement de la bibliothèque et de Premium. Décrivez simplement ce que vous cherchez.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.muted, height: 1.55, fontSize: 13),
      ),
    ],
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;
  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      width: double.infinity,
      margin: EdgeInsets.only(
        bottom: 13,
        left: message.fromUser ? 32 : 0,
        right: message.fromUser ? 0 : 8,
      ),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: message.fromUser
            ? AppColors.blue
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: message.fromUser
          ? Text(
              message.text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            )
          : AssistantMessageBody(text: message.text),
    ),
  );
}

class AssistantMessageBody extends StatelessWidget {
  const AssistantMessageBody({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final blocks = <({String text, bool table})>[];
    var lines = <String>[];
    var table = false;
    for (final line in text.split('\n')) {
      final next = line.trim().startsWith('|') && line.trim().endsWith('|');
      if (next != table && lines.isNotEmpty) {
        blocks.add((text: lines.join('\n'), table: table));
        lines = [];
      }
      table = next;
      lines.add(line);
    }
    if (lines.isNotEmpty) blocks.add((text: lines.join('\n'), table: table));
    Widget markdown(String data) => MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(fontFamily: 'Urbanist', fontSize: 14, height: 1.5),
        h1: const TextStyle(
          fontFamily: 'Urbanist',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        h2: const TextStyle(
          fontFamily: 'Urbanist',
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
        h3: const TextStyle(
          fontFamily: 'Urbanist',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        tableColumnWidth: const FixedColumnWidth(160),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks.map((block) {
        if (!block.table) return markdown(block.text);
        final columns = block.text.split('\n').first.split('|').length - 2;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: (columns * 160.0).clamp(320.0, 1600.0).toDouble(),
            child: markdown(block.text),
          ),
        );
      }).toList(),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox(
        width: 38,
        child: LinearProgressIndicator(minHeight: 3),
      ),
    ),
  );
}
