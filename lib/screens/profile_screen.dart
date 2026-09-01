import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../services/app_state.dart';
import '../widgets/brand_header.dart';
import '../widgets/section.dart';
import 'auth_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.state, required this.onAssistant});
  final AppState state; final VoidCallback onAssistant;
  @override Widget build(BuildContext context) {
    final user = state.session != null && state.session!.anonymous == false;
    final name = user ? state.session!.pseudo : 'Lecteur invité';
    return ListView(children: [
      const BrandHeader(compact: true),
      Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(23), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(23)), child: Column(children: [
        CircleAvatar(radius: 36, backgroundColor: AppColors.sky, child: Text(user ? name.substring(0, 1).toUpperCase() : 'L', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AppColors.blue))),
        const SizedBox(height: 12), Text(name, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 5), Text(user ? 'Compte Fasobiblio' : 'Connectez-vous pour retrouver votre compte', style: const TextStyle(fontSize: 12, color: AppColors.muted)), const SizedBox(height: 17),
        if (user) OutlinedButton.icon(onPressed: state.logout, icon: const Icon(Icons.logout_rounded), label: const Text('Se déconnecter')) else Row(children: [Expanded(child: FilledButton(onPressed: () => showAuthSheet(context, state, signup: true), child: const Text('Créer un compte'))), const SizedBox(width: 9), Expanded(child: OutlinedButton(onPressed: () => showAuthSheet(context, state, signup: false), child: const Text('Connexion')))]),
      ])),
      const SectionTitle('Services'),
      _Menu(icon: Icons.auto_awesome_rounded, title: 'Assistant d’étude', subtitle: 'Questions, explications et orientation', onTap: onAssistant),
      _Menu(icon: Icons.info_outline_rounded, title: 'À propos de Fasobiblio', subtitle: 'La bibliothèque numérique des apprenants', onTap: () => showAboutDialog(context: context, applicationName: 'Fasobiblio', applicationVersion: '2.0.0', applicationIcon: Image.asset('assets/branding/icon.png', width: 52), children: [const Text('Une application mobile native pensée pour apprendre, lire et réussir.')])),
      _Menu(icon: Icons.policy_outlined, title: 'Confidentialité et conditions', subtitle: 'Consulter les textes officiels', onTap: () => launchUrl(Uri.parse('https://fasobiblio.com'), mode: LaunchMode.externalApplication)),
      const Padding(padding: EdgeInsets.all(27), child: Text('Fasobiblio Mobile • version 2.0.0', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted))),
    ]);
  }
}
class _Menu extends StatelessWidget {
  const _Menu({required this.icon, required this.title, required this.subtitle, required this.onTap}); final IconData icon; final String title, subtitle; final VoidCallback onTap;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10), child: Material(color: Colors.white, borderRadius: BorderRadius.circular(17), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17), child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: AppColors.blue)), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted))])), const Icon(Icons.chevron_right_rounded, color: AppColors.muted)])))));
}
