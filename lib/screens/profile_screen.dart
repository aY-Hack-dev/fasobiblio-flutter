import 'package:flutter/material.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../services/app_state.dart';
import '../widgets/section.dart';
import 'auth_sheet.dart';
import 'information_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onAssistant, required this.onLibrary, required this.onNotifications});
  final AppState state;
  final VoidCallback onAssistant;
  final VoidCallback onLibrary;
  final VoidCallback onNotifications;

  void information(BuildContext context, InformationKind kind) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InformationScreen(kind: kind, state: state)));

  Future<void> _support(BuildContext context) async {
    if (!requireInternet(context, state)) return;
    final result = await showModalBottomSheet<(String, String)>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => const _SupportSheet());
    if (result == null || !context.mounted) return;
    try {
      await state.api.sendSupportMessage(type: result.$1, message: result.$2);
      if (context.mounted) showToast(context, 'Votre message a bien été envoyé à Fasobiblio.', success: true);
    } catch (error) {
      if (context.mounted) showToast(context, friendlyFailure(error, action: 'envoyer votre message'));
    }
  }

  Future<void> _suggest(BuildContext context) async {
    if (!requireInternet(context, state)) return;
    final result = await showModalBottomSheet<(String, String, String, String)>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => const _SuggestionSheet());
    if (result == null || !context.mounted) return;
    try {
      await state.api.sendSuggestion(title: result.$1, subject: result.$2, level: result.$3, details: result.$4);
      if (context.mounted) showToast(context, 'Suggestion envoyée. Merci de contribuer au catalogue !', success: true);
    } catch (error) {
      if (context.mounted) showToast(context, friendlyFailure(error, action: 'envoyer votre suggestion'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = state.session != null && !state.session!.anonymous;
    final name = connected ? state.session!.pseudo : 'Lecteur invité';
    final subscription = state.subscription;
    return ListView(children: [
      _ProfileCard(state: state, connected: connected, name: name),
      if (connected) _PremiumStatus(subscription: subscription, purchased: state.purchased.length),
      const SectionTitle('Mon espace'),
      _Menu(icon: AppIcons.library, title: 'Ma bibliothèque', subtitle: 'Favoris, liste de lecture et achats', onTap: onLibrary),
      _Menu(icon: AppIcons.fileCheck, title: 'Documents hors connexion', subtitle: 'Lectures conservées et dossier Download/Fasobiblio', onTap: () => information(context, InformationKind.downloads)),
      _Menu(icon: AppIcons.bell, title: 'Notifications', subtitle: state.unreadNotifications == 0 ? 'Vous êtes à jour' : '${state.unreadNotifications} nouvelle(s) annonce(s)', onTap: onNotifications, badge: state.unreadNotifications),
      const SectionTitle('Services Fasobiblio'),
      _Menu(icon: AppIcons.sparkles, title: 'Assistant d’étude', subtitle: 'Posez vos questions à l’assistant Fasobiblio', onTap: onAssistant),
      _Menu(icon: AppIcons.lightbulb, title: 'Suggérer un document', subtitle: 'Proposez un livre, un cours ou une ressource', onTap: () => _suggest(context)),
      _Menu(icon: AppIcons.support, title: 'Aide et assistance', subtitle: 'Écrivez directement à l’équipe Fasobiblio', onTap: () => _support(context)),
      const SectionTitle('Accessibilité'),
      _DarkModeTile(state: state),
      const SectionTitle('À propos'),
      _Menu(icon: AppIcons.info, title: 'À propos de Fasobiblio', subtitle: 'Notre mission et le fonctionnement de l’application', onTap: () => information(context, InformationKind.about)),
      _Menu(icon: AppIcons.fileText, title: 'Conditions d’utilisation', subtitle: 'Règles du service et contenus Premium', onTap: () => information(context, InformationKind.terms)),
      _Menu(icon: AppIcons.shield, title: 'Politique de confidentialité', subtitle: 'Compte, stockage local et paiements', onTap: () => information(context, InformationKind.privacy)),
      _Menu(icon: AppIcons.scale, title: 'Mentions légales et contact', subtitle: 'Éditeur et coordonnées de Fasobiblio', onTap: () => information(context, InformationKind.legal)),
      const Padding(padding: EdgeInsets.all(27), child: Text('Fasobiblio Mobile • version 3.4.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted))),
    ]);
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.state, required this.connected, required this.name});
  final AppState state;
  final bool connected;
  final String name;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D2853), AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(25)),
    child: Column(children: [
      CircleAvatar(radius: 38, backgroundColor: Colors.white, child: Text(connected && name.isNotEmpty ? name[0].toUpperCase() : 'L', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: AppColors.blue))),
      const SizedBox(height: 12),
      Text(name, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 4),
      Text(connected ? 'Compte Fasobiblio synchronisé' : 'Profitez du catalogue en mode invité', style: const TextStyle(fontSize: 12, color: Color(0xFFDCE6FF))),
      const SizedBox(height: 17),
      if (connected)
        OutlinedButton.icon(onPressed: state.logout, icon: const Icon(AppIcons.logout), label: const Text('Se déconnecter'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x66FFFFFF))))
      else
        Row(children: [Expanded(child: FilledButton(onPressed: () => showAuthSheet(context, state, signup: true), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue), child: const Text('Créer un compte'))), const SizedBox(width: 9), Expanded(child: OutlinedButton(onPressed: () => showAuthSheet(context, state, signup: false), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)), child: const Text('Connexion')))]),
    ]),
  );
}

class _PremiumStatus extends StatelessWidget {
  const _PremiumStatus({required this.subscription, required this.purchased});
  final Map<String, dynamic>? subscription;
  final int purchased;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: subscription == null ? Theme.of(context).colorScheme.surface : const Color(0xFFFFF8E3), border: Border.all(color: subscription == null ? Theme.of(context).dividerColor.withValues(alpha: .5) : const Color(0xFFEAD9A7)), borderRadius: BorderRadius.circular(18)),
    child: Row(children: [Icon(subscription == null ? AppIcons.user : AppIcons.premium, color: subscription == null ? AppColors.blue : AppColors.gold, size: 30), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subscription == null ? 'Compte gratuit' : '${subscription!['planName'] ?? 'Premium actif'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: subscription == null ? null : AppColors.ink)), const SizedBox(height: 3), Text(subscription == null ? '$purchased document(s) acheté(s)' : subscription!['lifetime'] == true ? 'Accès à vie' : 'Accès Premium actif', style: const TextStyle(fontSize: 11, color: AppColors.muted))]))]),
  );
}

class _DarkModeTile extends StatelessWidget {
  const _DarkModeTile({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17), child: SwitchListTile(value: state.darkMode, onChanged: state.toggleDarkMode, secondary: Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(13)), child: Icon(state.darkMode ? AppIcons.moon : AppIcons.sun, color: AppColors.blue)), title: const Text('Mode sombre', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Adapter l’interface pour la lecture nocturne', style: TextStyle(fontSize: 11, color: AppColors.muted)))),
  );
}

class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.title, required this.subtitle, required this.onTap, this.badge = 0});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.blue)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted))])), if (badge > 0) Badge(label: Text(badge > 99 ? '99+' : '$badge')) else const Icon(AppIcons.chevronRight, color: AppColors.muted)])))),
  );
}

class _SupportSheet extends StatefulWidget {
  const _SupportSheet();
  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  final controller = TextEditingController();
  String type = 'Assistance';
  static const topics = <(String, IconData)>[
    ('Assistance', AppIcons.support),
    ('Paiement', AppIcons.wallet),
    ('Document', AppIcons.bookOpen),
    ('Autre', AppIcons.more),
  ];
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Contacter Fasobiblio', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close))]),
      const SizedBox(height: 5),
      const Text('Quel sujet pouvons-nous traiter ?', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 15),
      Wrap(
        spacing: 9,
        runSpacing: 9,
        children: topics.map((topic) {
          final selected = type == topic.$1;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => setState(() => type = topic.$1),
            showCheckmark: false,
            avatar: Icon(topic.$2, size: 18, color: selected ? Colors.white : AppColors.blue),
            label: Text(topic.$1),
            labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface),
            selectedColor: AppColors.blue,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(color: selected ? AppColors.blue : Theme.of(context).dividerColor.withValues(alpha: .65)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          );
        }).toList(),
      ),
      const SizedBox(height: 15),
      TextField(controller: controller, onChanged: (_) => setState(() {}), minLines: 4, maxLines: 6, maxLength: 1000, decoration: const InputDecoration(labelText: 'Votre message', hintText: 'Décrivez votre demande…')),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: controller.text.trim().length < 4 ? null : () => Navigator.pop(context, (type, controller.text.trim())), icon: const Icon(AppIcons.send), label: const Text('Envoyer'))),
    ]),
  );
}

class _SuggestionSheet extends StatefulWidget {
  const _SuggestionSheet();
  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  final title = TextEditingController();
  final subject = TextEditingController();
  final level = TextEditingController();
  final details = TextEditingController();
  @override
  void dispose() { title.dispose(); subject.dispose(); level.dispose(); details.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SingleChildScrollView(padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.viewInsetsOf(context).bottom + 20), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('Suggérer un document', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close))]), const SizedBox(height: 12), TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Titre du document')), const SizedBox(height: 10), TextField(controller: subject, decoration: const InputDecoration(labelText: 'Matière ou thème')), const SizedBox(height: 10), TextField(controller: level, decoration: const InputDecoration(labelText: 'Niveau')), const SizedBox(height: 10), TextField(controller: details, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Précisions')), const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: title.text.trim().length < 2 ? null : () => Navigator.pop(context, (title.text.trim(), subject.text.trim(), level.text.trim(), details.text.trim())), icon: const Icon(AppIcons.send), label: const Text('Envoyer la suggestion')))]));
}
