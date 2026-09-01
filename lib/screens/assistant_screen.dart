import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.state});
  final AppState state;

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _ChatMessage {
  const _ChatMessage(this.text, {required this.fromUser});
  final String text;
  final bool fromUser;
}

class _AssistantScreenState extends State<AssistantScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  final messages = <_ChatMessage>[];
  bool busy = false;

  @override
  void dispose() {
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> ask([String? suggestion]) async {
    final question = (suggestion ?? controller.text).trim();
    if (question.isEmpty || busy) return;
    if (!requireInternet(context, widget.state)) return;
    controller.clear();
    setState(() {
      messages.add(_ChatMessage(question, fromUser: true));
      busy = true;
    });
    _scrollDown();
    try {
      final answer = await widget.state.api.assistant(question);
      if (!mounted) return;
      setState(() => messages.add(_ChatMessage(answer, fromUser: false)));
    } catch (error) {
      if (mounted) showToast(context, friendlyFailure(error, action: 'obtenir une réponse de l’assistant'));
    } finally {
      if (mounted) setState(() => busy = false);
      _scrollDown();
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (scrollController.hasClients) scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 260), curve: Curves.easeOut);
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(children: [
          CircleAvatar(backgroundColor: AppColors.blue, foregroundColor: Colors.white, child: Icon(Icons.smart_toy_rounded, size: 21)),
          SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assistant Fasobiblio', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), SizedBox(height: 2), Row(children: [CircleAvatar(radius: 4, backgroundColor: Color(0xFF22C55E)), SizedBox(width: 5), Text('Assistant bibliothèque', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.muted))])])),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: messages.isEmpty
            ? _Welcome(onSuggestion: ask)
            : ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                itemCount: messages.length + (busy ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) return const _TypingBubble();
                  return _MessageBubble(message: messages[index]);
                },
              ),
        ),
        Container(
          color: surface,
          padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.paddingOf(context).bottom + 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(hintText: 'Posez votre question…', contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              onChanged: (_) => setState(() {}),
            )),
            const SizedBox(width: 9),
            IconButton.filled(onPressed: busy ? null : ask, icon: const Icon(Icons.send_rounded), tooltip: 'Envoyer', style: IconButton.styleFrom(minimumSize: const Size(50, 50))),
          ]),
        ),
      ]),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onSuggestion});
  final ValueChanged<String> onSuggestion;

  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(24, 48, 24, 20), children: [
    Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF7157D9)]), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.smart_toy_rounded, color: Colors.white, size: 34))),
    const SizedBox(height: 18),
    Text('Comment puis-je vous aider ?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
    const SizedBox(height: 8),
    const Text('Interrogez-moi sur le catalogue, vos lectures ou le fonctionnement de Fasobiblio.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, height: 1.5)),
    const SizedBox(height: 28),
    ...['Trouve-moi un roman africain', 'Comment fonctionne Premium ?', 'Recommande-moi un document scientifique'].map((text) => Padding(padding: const EdgeInsets.only(bottom: 9), child: OutlinedButton.icon(onPressed: () => onSuggestion(text), icon: const Icon(Icons.auto_awesome_rounded, size: 18), label: Align(alignment: Alignment.centerLeft, child: Text(text)), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14))))),
  ]);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final _ChatMessage message;

  @override
  Widget build(BuildContext context) => Align(
    alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .82),
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(color: message.fromUser ? AppColors.blue : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.only(topLeft: const Radius.circular(18), topRight: const Radius.circular(18), bottomLeft: Radius.circular(message.fromUser ? 18 : 5), bottomRight: Radius.circular(message.fromUser ? 5 : 18)), border: message.fromUser ? null : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5))),
      child: message.fromUser
        ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.45))
        : MarkdownBody(
            data: message.text,
            selectable: true,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(p: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.55), h1: Theme.of(context).textTheme.titleLarge, h2: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w900), blockquoteDecoration: const BoxDecoration(color: AppColors.sky, border: Border(left: BorderSide(color: AppColors.blue, width: 3))), codeblockDecoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(9))),
          ),
    ),
  );
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();
  @override
  Widget build(BuildContext context) => Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 13), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)), child: const SizedBox(width: 38, child: LinearProgressIndicator(minHeight: 3))));
}
