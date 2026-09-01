import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_state.dart';
import '../widgets/section.dart';
import 'auth_sheet.dart';
import 'information_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onAssistant, required this.onLibrary});
  final AppState state;
  final VoidCallback onAssistant;
  final VoidCallback onLibrary;

  void information(BuildContext context, InformationKind kind) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InformationScreen(kind: kind)));

  @override Widget build(BuildContext context) {
    final user = state.session != null && state.session!.anonymous == false;
    final name = user ? state.session!.pseudo : 'Lecteur invité';
    final subscription = state.subscription;
    final lastSync = state.lastSync;
    return ListView(children: [
      Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(23), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(23)), child: Column(children: [
        CircleAvatar(radius: 36, backgroundColor: AppColors.sky, child: Text(user ? name.substring(0, 1).toUpperCase() : 'L', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.blue))),
        const SizedBox(height: 12), Text(name, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 5), Text(user ? 'Compte Fasobiblio' : 'Connectez-vous pour retrouver votre compte', style: const TextStyle(fontSize: 12, color: AppColors.muted)), const SizedBox(height: 17),
        if (user) OutlinedButton.icon(onPressed: state.logout, icon: const Icon(Icons.logout_rounded), label: const Text('Se déconnecter')) else Row(children: [Expanded(child: FilledButton(onPressed: () => showAuthSheet(context, state, signup: true), child: const Text('Créer un compte'))), const SizedBox(width: 9), Expanded(child: OutlinedButton(onPressed: () => showAuthSheet(context, state, signup: false), child: const Text('Connexion')))]),
      ])),
      if (user) Container(margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: subscription == null ? Colors.white : const Color(0xFFFFF8E3), border: Border.all(color: subscription == null ? AppColors.line : const Color(0xFFEAD9A7)), borderRadius: BorderRadius.circular(18)), child: Row(children: [Icon(subscription == null ? Icons.person_outline_rounded : Icons.workspace_premium_rounded, color: subscription == null ? AppColors.blue : AppColors.gold, size: 30), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(subscription == null ? 'Compte gratuit' : '${subscription['planName'] ?? 'Premium actif'}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)), const SizedBox(height: 3), Text(subscription == null ? '${state.purchased.length} document(s) acheté(s)' : subscription['lifetime'] == true ? 'Accès à vie' : 'Accès Premium synchronisé', style: const TextStyle(fontSize: 11, color: AppColors.muted))])), IconButton(onPressed: state.refreshAccount, icon: const Icon(Icons.refresh_rounded), tooltip: 'Actualiser')])),
      const SectionTitle('Ma bibliothèque'),
      _Menu(icon: Icons.shopping_bag_outlined, title: 'Mes achats', subtitle: '${state.purchased.length} document(s) Premium', onTap: onLibrary),
      _Menu(icon: Icons.download_done_rounded, title: 'Lecture hors connexion', subtitle: 'PDF en cache et dossier Download/Fasobiblio', onTap: () => information(context, InformationKind.downloads)),
      const SectionTitle('Services'),
      _Menu(icon: Icons.auto_awesome_rounded, title: 'Assistant d’étude', subtitle: 'Questions, explications et orientation', onTap: onAssistant),
      _Menu(icon: state.offline ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, title: state.offline ? 'Mode hors connexion' : 'Données synchronisées', subtitle: lastSync == null ? 'Aucune synchronisation enregistrée' : 'Dernière synchronisation : ${_date(lastSync)}', onTap: () => state.load(refresh: true)),
      const SectionTitle('Aide & informations'),
      _Menu(icon: Icons.info_outline_rounded, title: 'À propos de Fasobiblio', subtitle: 'Mission et fonctionnement de l’application', onTap: () => information(context, InformationKind.about)),
      _Menu(icon: Icons.description_outlined, title: 'Conditions d’utilisation', subtitle: 'Règles du service et contenus Premium', onTap: () => information(context, InformationKind.terms)),
      _Menu(icon: Icons.privacy_tip_outlined, title: 'Politique de confidentialité', subtitle: 'Compte, stockage local et paiements', onTap: () => information(context, InformationKind.privacy)),
      _Menu(icon: Icons.balance_rounded, title: 'Mentions légales et contact', subtitle: 'Éditeur et coordonnées de Fasobiblio', onTap: () => information(context, InformationKind.legal)),
      const Padding(padding: EdgeInsets.all(27), child: Text('Fasobiblio Mobile • version 2.2.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted))),
    ]);
  }

  String _date(DateTime value) => '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} à ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.blue)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)])))));
}
