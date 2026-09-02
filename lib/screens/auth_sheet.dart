import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_feedback.dart';
import '../services/app_state.dart';

Future<void> showAuthSheet(BuildContext context, AppState state, {required bool signup}) async {
  final pseudo = TextEditingController(), password = TextEditingController(), phone = TextEditingController();
  String? error; var busy = false;
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) {
    Future<void> submit() async {
      if (!RegExp(r'^[A-Za-z0-9_.-]{3,24}$').hasMatch(pseudo.text)) { setModalState(() => error = 'Le pseudo doit contenir 3 à 24 caractères.'); return; }
      if (password.text.length < 8) { setModalState(() => error = 'Le mot de passe doit contenir au moins 8 caractères.'); return; }
      if (signup && !RegExp(r'^\d{8,10}$').hasMatch(phone.text.replaceAll(RegExp(r'\D'), ''))) { setModalState(() => error = 'Le numéro de téléphone est invalide.'); return; }
      setModalState(() { busy = true; error = null; });
      try { signup ? await state.signup(pseudo.text, password.text, phone.text) : await state.login(pseudo.text, password.text); if (sheetContext.mounted) Navigator.pop(sheetContext); }
      catch (e) { setModalState(() => error = friendlyFailure(e, action: signup ? 'créer votre compte' : 'vous connecter')); }
      finally { if (sheetContext.mounted) setModalState(() => busy = false); }
    }
    return Padding(padding: EdgeInsets.fromLTRB(22, 0, 22, MediaQuery.viewInsetsOf(context).bottom + 24), child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(children: [Expanded(child: Text(signup ? 'Créer mon compte' : 'Se connecter', style: Theme.of(context).textTheme.headlineMedium)), IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(AppIcons.close))]), const SizedBox(height: 3), Text(signup ? 'Synchronisez votre accès Fasobiblio.' : 'Heureux de vous revoir.', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      const SizedBox(height: 20), TextField(controller: pseudo, textInputAction: TextInputAction.next, autocorrect: false, decoration: const InputDecoration(labelText: 'Nom d’utilisateur', prefixIcon: Icon(AppIcons.user))),
      const SizedBox(height: 12), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Mot de passe', prefixIcon: Icon(AppIcons.lock))),
      if (signup) ...[const SizedBox(height: 12), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Téléphone de récupération', prefixIcon: Icon(AppIcons.phone)))],
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(fontSize: 12, color: Colors.red))),
      const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Veuillez patienter…' : signup ? 'Créer le compte' : 'Connexion'))),
    ])));
  }));
  pseudo.dispose(); password.dispose(); phone.dispose();
}
