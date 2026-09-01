import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/fasobiblio_api.dart';

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.api}); final FasobiblioApi api;
  @override State<AssistantScreen> createState() => _AssistantScreenState();
}
class _AssistantScreenState extends State<AssistantScreen> {
  final controller = TextEditingController(); String answer = ''; bool busy = false;
  @override void dispose() { controller.dispose(); super.dispose(); }
  Future<void> ask() async {
    if (controller.text.trim().isEmpty || busy) return;
    setState(() { busy = true; answer = ''; });
    try { final value = await widget.api.assistant(controller.text.trim()); if (mounted) setState(() => answer = value); }
    catch (e) { if (mounted) setState(() => answer = e.toString().replaceFirst('Exception: ', '')); }
    finally { if (mounted) setState(() => busy = false); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Assistant Fasobiblio')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, Color(0xFF7157D9)]), borderRadius: BorderRadius.circular(22)), child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 33))),
      const SizedBox(height: 16), Text('Comment puis-je vous aider ?', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 8), const Text('Posez une question pédagogique ou décrivez le document que vous cherchez.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 22), TextField(controller: controller, minLines: 4, maxLines: 7, decoration: const InputDecoration(hintText: 'Exemple : explique-moi simplement la photosynthèse…', alignLabelWithHint: true)),
      const SizedBox(height: 13), FilledButton.icon(onPressed: busy ? null : ask, icon: const Icon(Icons.send_rounded), label: Text(busy ? 'Analyse en cours…' : 'Envoyer ma question')),
      if (busy) const Padding(padding: EdgeInsets.all(25), child: Center(child: CircularProgressIndicator())),
      if (answer.isNotEmpty) Container(margin: const EdgeInsets.only(top: 20), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.line)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Row(children: [Icon(Icons.auto_awesome_rounded, color: AppColors.blue, size: 19), SizedBox(width: 8), Text('Réponse', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink))]), const SizedBox(height: 12), SelectableText(answer, style: const TextStyle(height: 1.55, color: AppColors.ink))])),
    ]),
  );
}
