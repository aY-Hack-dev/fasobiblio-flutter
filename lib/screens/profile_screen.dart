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
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (_) => const _SheetFrame(child: _SupportSheet()),
    );
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
    final result = await showModalBottomSheet<(String, String, String, String)>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (_) => const _SheetFrame(child: _SuggestionSheet()),
    );
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
      _ProfileHero(state: state, connected: connected, name: name),
      if (connected) _PremiumStatus(subscription: subscription, purchased: state.purchased.length),
      const SectionTitle('Mon espace'),
      _Menu(icon: AppIcons.library, title: 'Ma bibliothèque', subtitle: 'Favoris, liste de lecture et achats', onTap: onLibrary),
      _Menu(icon: AppIcons.fileCheck, title: 'Documents hors connexion', subtitle: 'Lectures conservées et dossier Download/Fasobiblio', onTap: () => information(context, InformationKind.downloads)),
      _Menu(icon: AppIcons.bell, title: 'Notifications', subtitle: state.unreadNotifications == 0 ? 'Vous êtes à jour' : '${state.unreadNotifications} nouvelle(s) annonce(s)', onTap: onNotifications, badge: state.unreadNotifications),
      const SectionTitle('Services Fasobiblio'),
      _Menu(icon: AppIcons.sparkles, title: 'Assistant d’étude', subtitle: 'Posez vos questions à l’assistant Fasobiblio', onTap: onAssistant, accent: true),
      _Menu(icon: AppIcons.lightbulb, title: 'Suggérer un document', subtitle: 'Proposez un livre, un cours ou une ressource', onTap: () => _suggest(context)),
      _Menu(icon: AppIcons.support, title: 'Aide et assistance', subtitle: 'Écrivez directement à l’équipe Fasobiblio', onTap: () => _support(context)),
      const SectionTitle('Accessibilité'),
      _DarkModeTile(state: state),
      const SectionTitle('À propos'),
      _Menu(icon: AppIcons.info, title: 'À propos de Fasobiblio', subtitle: 'Notre mission et le fonctionnement de l’application', onTap: () => information(context, InformationKind.about)),
      _Menu(icon: AppIcons.fileText, title: 'Conditions d’utilisation', subtitle: 'Règles du service et contenus Premium', onTap: () => information(context, InformationKind.terms)),
      _Menu(icon: AppIcons.shield, title: 'Politique de confidentialité', subtitle: 'Compte, stockage local et paiements', onTap: () => information(context, InformationKind.privacy)),
      _Menu(icon: AppIcons.scale, title: 'Mentions légales et contact', subtitle: 'Éditeur et coordonnées de Fasobiblio', onTap: () => information(context, InformationKind.legal)),
      const Padding(padding: EdgeInsets.fromLTRB(27, 20, 27, 115), child: Text('Fasobiblio Mobile • version 3.4.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted))),
    ]);
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.state, required this.connected, required this.name});
  final AppState state;
  final bool connected;
  final String name;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0A1C3A), Color(0xFF123E87), AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x301860F0), blurRadius: 28, offset: Offset(0, 13))],
    ),
    child: Stack(children: [
      Positioned(right: -30, top: -35, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), shape: BoxShape.circle))),
      Column(children: [
        Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(23), boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, 7))]),
            alignment: Alignment.center,
            child: Text(connected && name.isNotEmpty ? name[0].toUpperCase() : 'L', style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: AppColors.blue)),
          ),
          const SizedBox(width: 15),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 22, weight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 5),
            Text(connected ? 'Compte Fasobiblio synchronisé' : 'Explorez le savoir en mode invité', style: const TextStyle(fontSize: 11.5, color: Color(0xFFDCE7FF))),
          ])),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _MiniStat(icon: AppIcons.heart, value: '${state.favorites.length}', label: 'Favoris')),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(icon: AppIcons.bookmark, value: '${state.later.length}', label: 'À lire')),
          const SizedBox(width: 8),
          Expanded(child: _MiniStat(icon: AppIcons.shoppingBag, value: '${state.purchased.length}', label: 'Achats')),
        ]),
        const SizedBox(height: 18),
        if (connected)
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: state.logout, icon: const Icon(AppIcons.logout), label: const Text('Se déconnecter'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Color(0x55FFFFFF)), minimumSize: const Size(0, 46))))
        else
          Row(children: [
            Expanded(child: FilledButton(onPressed: () => showAuthSheet(context, state, signup: true), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue), child: const Text('Créer un compte'))),
            const SizedBox(width: 9),
            Expanded(child: OutlinedButton(onPressed: () => showAuthSheet(context, state, signup: false), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), minimumSize: const Size(0, 46)), child: const Text('Connexion'))),
          ]),
      ]),
    ]),
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Icon(icon, size: 16, color: const Color(0xFFBFD2FF)), const SizedBox(height: 5), Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFFCAD7EF))) ]),
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
    decoration: BoxDecoration(color: subscription == null ? Theme.of(context).colorScheme.surface : const Color(0xFFFFF8E3), border: Border.all(color: subscription == null ? Theme.of(context).dividerColor.withValues(alpha: .5) : const Color(0xFFEAD9A7)), borderRadius: BorderRadius.circular(19)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: subscription == null ? AppColors.sky : Colors.white, borderRadius: BorderRadius.circular(14)), child: Icon(subscription == null ? AppIcons.user : AppIcons.premium, color: subscription == null ? AppColors.blue : AppColors.gold)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subscription == null ? 'Compte gratuit' : '${subscription!['planName'] ?? 'Premium actif'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.w900, color: subscription == null ? null : AppColors.ink)), const SizedBox(height: 3), Text(subscription == null ? '$purchased document(s) acheté(s)' : subscription!['lifetime'] == true ? 'Accès à vie' : 'Accès Premium actif', style: const TextStyle(fontSize: 11, color: AppColors.muted))]))
    ]),
  );
}

class _DarkModeTile extends StatelessWidget {
  const _DarkModeTile({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(19), child: SwitchListTile(value: state.darkMode, onChanged: state.toggleDarkMode, secondary: Container(width: 44, height: 44, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.sky, Color(0xFFE8F0FF)]), borderRadius: BorderRadius.circular(13)), child: Icon(state.darkMode ? AppIcons.moon : AppIcons.sun, color: AppColors.blue)), title: const Text('Mode sombre', style: TextStyle(fontWeight: FontWeight.w800)), subtitle: const Text('Adapter l’interface pour la lecture nocturne', style: TextStyle(fontSize: 11, color: AppColors.muted)))),
  );
}

class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.title, required this.subtitle, required this.onTap, this.badge = 0, this.accent = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badge;
  final bool accent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: Material(
      color: accent ? const Color(0xFF102C5C) : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(19),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(width: 46, height: 46, decoration: BoxDecoration(color: accent ? Colors.white.withValues(alpha: .10) : AppColors.sky, borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: accent ? const Color(0xFFBFD2FF) : AppColors.blue)),
            const SizedBox(width: 13),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: accent ? Colors.white : null)), const SizedBox(height: 3), Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: accent ? const Color(0xFFCAD7EF) : AppColors.muted))])),
            if (badge > 0) Badge(label: Text(badge > 99 ? '99+' : '$badge')) else Icon(AppIcons.chevronRight, color: accent ? const Color(0xFFBFD2FF) : AppColors.muted),
          ]),
        ),
      ),
    ),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Material(
        color: dark ? const Color(0xFF111B2C) : Colors.white,
        elevation: 20,
        shadowColor: Colors.black.withValues(alpha: .2),
        clipBehavior: Clip.antiAlias,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(width: 42, height: 5, decoration: BoxDecoration(color: dark ? const Color(0xFF43516A) : const Color(0xFFD4DDEA), borderRadius: BorderRadius.circular(10))),
            Flexible(child: child),
            SizedBox(height: MediaQuery.viewPaddingOf(context).bottom == 0 ? 10 : 4),
          ],
        ),
      ),
    );
  }
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
    padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Contacter Fasobiblio', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close))]),
      const SizedBox(height: 5),
      const Text('Quel sujet pouvons-nous traiter ?', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 15),
      Wrap(spacing: 9, runSpacing: 9, children: topics.map((topic) {
        final selected = type == topic.$1;
        return ChoiceChip(selected: selected, onSelected: (_) => setState(() => type = topic.$1), showCheckmark: false, avatar: Icon(topic.$2, size: 18, color: selected ? Colors.white : AppColors.blue), label: Text(topic.$1), labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface), selectedColor: AppColors.blue, backgroundColor: Theme.of(context).colorScheme.surface, side: BorderSide(color: selected ? AppColors.blue : Theme.of(context).dividerColor.withValues(alpha: .65)), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));
      }).toList()),
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
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Suggérer un document', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(AppIcons.close))]),
      const SizedBox(height: 12),
      TextField(controller: title, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Titre du document')),
      const SizedBox(height: 10),
      TextField(controller: subject, decoration: const InputDecoration(labelText: 'Matière ou thème')),
      const SizedBox(height: 10),
      TextField(controller: level, decoration: const InputDecoration(labelText: 'Niveau')),
      const SizedBox(height: 10),
      TextField(controller: details, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Précisions')),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: title.text.trim().length < 2 ? null : () => Navigator.pop(context, (title.text.trim(), subject.text.trim(), level.text.trim(), details.text.trim())), icon: const Icon(AppIcons.send), label: const Text('Envoyer la suggestion'))),
    ]),
  );
}
