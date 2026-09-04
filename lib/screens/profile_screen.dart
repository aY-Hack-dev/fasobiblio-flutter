import 'package:flutter/material.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../services/app_state.dart';
import 'auth_sheet.dart';
import 'information_screen.dart';
import 'offline_documents_screen.dart';
import 'payment_flow.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onAssistant, required this.onLibrary, required this.onNotifications});
  final AppState state;
  final VoidCallback onAssistant;
  final VoidCallback onLibrary;
  final VoidCallback onNotifications;

  void information(BuildContext context, InformationKind kind) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InformationScreen(kind: kind, state: state)));

  Future<void> _support(BuildContext context) async {
    if (!requireInternet(context, state)) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (_) => _SheetFrame(child: _SupportSheet(state: state)),
    );
  }

  Future<void> _suggest(BuildContext context) async {
    if (!requireInternet(context, state)) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .48),
      builder: (_) => _SheetFrame(child: _SuggestionSheet(state: state)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final connected = state.session != null && !state.session!.anonymous;
    final name = connected ? state.session!.pseudo : 'Lecteur invité';
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 110),
      children: [
        _ProfileHeader(state: state, connected: connected, name: name),
        const SizedBox(height: 14),
        _AppearanceCard(state: state),
        const SizedBox(height: 14),
        _Group(children: [
          _RowItem(icon: AppIcons.library, title: 'Ma bibliothèque', onTap: onLibrary),
          _RowItem(icon: AppIcons.fileCheck, title: 'Documents hors connexion', onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OfflineDocumentsScreen()))),
          _RowItem(icon: AppIcons.bell, title: 'Notifications', badge: state.unreadNotifications, onTap: onNotifications),
        ]),
        const SizedBox(height: 14),
        _Group(children: [
          _RowItem(icon: AppIcons.sparkles, title: 'Assistant d’étude', onTap: onAssistant),
          _RowItem(icon: AppIcons.lightbulb, title: 'Suggérer un document', onTap: () => _suggest(context)),
          _RowItem(icon: AppIcons.support, title: 'Aide et assistance', onTap: () => _support(context)),
          _RowItem(icon: AppIcons.heart, title: 'Faire un don', onTap: () => makeDonation(context, state)),
        ]),
        const SizedBox(height: 14),
        _Group(children: [
          _RowItem(icon: AppIcons.info, title: 'À propos de Fasobiblio', onTap: () => information(context, InformationKind.about)),
          _RowItem(icon: AppIcons.fileText, title: 'Conditions d’utilisation', onTap: () => information(context, InformationKind.terms)),
          _RowItem(icon: AppIcons.shield, title: 'Politique de confidentialité', onTap: () => information(context, InformationKind.privacy)),
          _RowItem(icon: AppIcons.scale, title: 'Mentions légales et contact', onTap: () => information(context, InformationKind.legal)),
        ]),
        const SizedBox(height: 18),
        if (connected) TextButton.icon(
          icon: const Icon(AppIcons.logout),
          label: const Text('Se déconnecter'),
          onPressed: () async {
            final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
              title: const Text('Se déconnecter ?'),
              content: const Text('Vous pourrez vous reconnecter pour retrouver vos accès.'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Se déconnecter')),
              ],
            ));
            if (confirmed != true) return;
            try { await state.logout(); } catch (error) {
              if (context.mounted) showToast(context, friendlyFailure(error, action: 'vous déconnecter'));
            }
          },
        ),
        const Text('Fasobiblio Mobile • version 3.5.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.5, color: AppColors.muted)),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state, required this.connected, required this.name});
  final AppState state;
  final bool connected;
  final String name;

  @override
  Widget build(BuildContext context) => Column(children: [
    Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF071A38), Color(0xFF124ED8), Color(0xFF3385FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x2010379D), blurRadius: 18, offset: Offset(0, 8))],
      ),
      child: Column(children: [
        SizedBox(height: 96, child: Stack(children: [
          const Positioned.fill(child: CustomPaint(painter: _ProfilePatternPainter())),
          Positioned(left: 16, top: 16, child: Container(
            width: 64, height: 64, alignment: Alignment.center,
            decoration: BoxDecoration(color: const Color(0xEEFFFFFF), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white, width: 2)),
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'F', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.blueDeep)),
          )),
          Positioned(right: 14, top: 14, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0x24FFFFFF), borderRadius: BorderRadius.circular(99)),
            child: Text(!connected ? 'Mode invité' : state.subscription != null ? 'Premium' : 'Compte gratuit', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          )),
        ])),
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xDD071A38),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 3),
            Text(connected ? '@${state.session!.pseudo}' : 'Votre espace de lecture personnel', style: const TextStyle(fontSize: 11, color: Color(0xFFBBD1F6))),
          ]),
        ),
      ]),
    ),
    const SizedBox(height: 12),
    if (!connected) Row(children: [
      Expanded(child: FilledButton(onPressed: () => showAuthSheet(context, state, signup: false), child: const Text('Connexion'))),
      const SizedBox(width: 8),
      Expanded(child: OutlinedButton(onPressed: () => showAuthSheet(context, state, signup: true), child: const Text('Créer un compte', textAlign: TextAlign.center))),
    ]) else Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _HeaderStat(value: '${state.favorites.length}', label: 'Favoris'),
        _HeaderStat(value: '${state.later.length}', label: 'À lire'),
        _HeaderStat(value: '${state.purchased.length}', label: 'Achats'),
      ]),
    ),
  ]);
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.primary)),
    const SizedBox(height: 3),
    Text(label, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
  ]));
}

class _ProfilePatternPainter extends CustomPainter {
  const _ProfilePatternPainter();
  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < 3; i++) {
      final offset = i * 16.0;
      final path = Path()..moveTo(size.width * .35, size.height)
        ..cubicTo(size.width * .65, -offset, size.width * .8, size.height + offset, size.width, 16 + offset)
        ..lineTo(size.width, size.height)..close();
      canvas.drawPath(path, Paint()..color = Colors.white.withValues(alpha: .07 + i * .025));
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .4))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [Icon(AppIcons.sun, size: 18), SizedBox(width: 8), Text('Apparence', style: TextStyle(fontWeight: FontWeight.w900))]),
      const SizedBox(height: 11),
      Row(children: [
        Expanded(child: _AppearanceChoice(icon: AppIcons.sun, label: 'Clair', selected: state.themeMode == 'light', onTap: () => state.setThemeMode('light'))),
        const SizedBox(width: 8),
        Expanded(child: _AppearanceChoice(icon: AppIcons.moon, label: 'Sombre', selected: state.themeMode == 'dark', onTap: () => state.setThemeMode('dark'))),
        const SizedBox(width: 8),
        Expanded(child: _AppearanceChoice(icon: Icons.brightness_auto_outlined, label: 'Système', selected: state.themeMode == 'system', onTap: () => state.setThemeMode('system'))),
      ]),
    ]),
  );
}

class _AppearanceChoice extends StatelessWidget {
  const _AppearanceChoice({required this.icon, required this.label, required this.selected, required this.onTap});
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(13),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: selected ? const Color(0xFFEAF1FF) : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: .45), borderRadius: BorderRadius.circular(13), border: Border.all(color: selected ? AppColors.blueDeep.withValues(alpha: .35) : Colors.transparent)),
      child: Column(children: [Icon(icon, size: 19, color: selected ? AppColors.blueDeep : AppColors.muted), const SizedBox(height: 5), Text(label, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: selected ? AppColors.blueDeep : AppColors.muted))]),
    ),
  );
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .4))),
    child: Column(children: List.generate(children.length * 2 - 1, (i) => i.isEven ? children[i ~/ 2] : Divider(height: 1, indent: 48, color: Theme.of(context).dividerColor.withValues(alpha: .38)))),
  );
}

class _RowItem extends StatelessWidget {
  const _RowItem({required this.icon, required this.title, required this.onTap, this.badge = 0});
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final int badge;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      child: Row(children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .78)),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
        if (badge > 0) Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(99)), child: Text(badge > 99 ? '99+' : '$badge', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppColors.blueDeep))),
        const SizedBox(width: 5),
        const Icon(AppIcons.chevronRight, size: 17, color: AppColors.muted),
      ]),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [const SizedBox(height: 10), Container(width: 42, height: 5, decoration: BoxDecoration(color: dark ? const Color(0xFF43516A) : const Color(0xFFD4DDEA), borderRadius: BorderRadius.circular(10))), Flexible(child: child), SizedBox(height: MediaQuery.viewPaddingOf(context).bottom == 0 ? 10 : 4)]),
      ),
    );
  }
}

class _SupportSheet extends StatefulWidget {
  const _SupportSheet({required this.state});
  final AppState state;
  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  final controller = TextEditingController();
  String type = 'Assistance';
  bool busy = false;
  String? error;
  static const topics = <(String, IconData)>[('Assistance', AppIcons.support), ('Paiement', AppIcons.wallet), ('Document', AppIcons.bookOpen), ('Autre', AppIcons.more)];
  @override
  void dispose() { controller.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (controller.text.trim().length < 4) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.state.api.sendSupportMessage(type: type, message: controller.text.trim());
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final messengerContext = context;
      Navigator.pop(context);
      if (messengerContext.mounted) showToast(messengerContext, 'Votre message a bien été envoyé à Fasobiblio.', success: true);
    } catch (e) {
      if (mounted) setState(() { busy = false; error = friendlyFailure(e, action: 'envoyer votre message'); });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Contacter Fasobiblio', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: busy ? null : () => Navigator.pop(context), icon: const Icon(AppIcons.close))]),
      const SizedBox(height: 5),
      const Text('Quel sujet pouvons-nous traiter ?', style: TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 15),
      Wrap(spacing: 9, runSpacing: 9, children: topics.map((topic) { final selected = type == topic.$1; return ChoiceChip(selected: selected, onSelected: busy ? null : (_) => setState(() => type = topic.$1), showCheckmark: false, avatar: Icon(topic.$2, size: 18, color: selected ? Colors.white : AppColors.blue), label: Text(topic.$1), labelStyle: TextStyle(fontWeight: FontWeight.w800, color: selected ? Colors.white : Theme.of(context).colorScheme.onSurface), selectedColor: AppColors.blue, backgroundColor: Theme.of(context).colorScheme.surface); }).toList()),
      const SizedBox(height: 15),
      TextField(controller: controller, enabled: !busy, onChanged: (_) => setState(() {}), minLines: 4, maxLines: 6, maxLength: 1000, decoration: const InputDecoration(labelText: 'Votre message', hintText: 'Décrivez votre demande…')),
      if (error != null) Text(error!, style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy || controller.text.trim().length < 4 ? null : submit, icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(AppIcons.send), label: Text(busy ? 'Envoi en cours…' : 'Envoyer'))),
    ]),
  );
}

class _SuggestionSheet extends StatefulWidget {
  const _SuggestionSheet({required this.state});
  final AppState state;
  @override
  State<_SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<_SuggestionSheet> {
  final title = TextEditingController();
  final subject = TextEditingController();
  final level = TextEditingController();
  final details = TextEditingController();
  bool busy = false;
  String? error;
  @override
  void dispose() { title.dispose(); subject.dispose(); level.dispose(); details.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (title.text.trim().length < 2) return;
    setState(() { busy = true; error = null; });
    try {
      await widget.state.api.sendSuggestion(title: title.text.trim(), subject: subject.text.trim(), level: level.text.trim(), details: details.text.trim());
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      final messengerContext = context;
      Navigator.pop(context);
      if (messengerContext.mounted) showToast(messengerContext, 'Suggestion envoyée. Merci de contribuer au catalogue !', success: true);
    } catch (e) {
      if (mounted) setState(() { busy = false; error = friendlyFailure(e, action: 'envoyer votre suggestion'); });
    }
  }

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.viewInsetsOf(context).bottom + 22),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('Suggérer un document', style: Theme.of(context).textTheme.titleLarge)), IconButton(onPressed: busy ? null : () => Navigator.pop(context), icon: const Icon(AppIcons.close))]),
      const SizedBox(height: 12),
      TextField(controller: title, enabled: !busy, onChanged: (_) => setState(() {}), decoration: const InputDecoration(labelText: 'Titre du document')),
      const SizedBox(height: 10),
      TextField(controller: subject, enabled: !busy, decoration: const InputDecoration(labelText: 'Matière ou thème')),
      const SizedBox(height: 10),
      TextField(controller: level, enabled: !busy, decoration: const InputDecoration(labelText: 'Niveau')),
      const SizedBox(height: 10),
      TextField(controller: details, enabled: !busy, minLines: 3, maxLines: 5, decoration: const InputDecoration(labelText: 'Précisions')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C), fontWeight: FontWeight.w700))),
      const SizedBox(height: 14),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy || title.text.trim().length < 2 ? null : submit, icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(AppIcons.send), label: Text(busy ? 'Envoi en cours…' : 'Envoyer la suggestion'))),
    ]),
  );
}
