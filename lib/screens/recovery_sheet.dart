import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_picker/country_picker.dart';
import '../services/app_state.dart';
import '../core/app_feedback.dart';

Future<void> showRecoverySheet(BuildContext context, AppState state) => showModalBottomSheet<void>(
  context: context, isScrollControlled: true, useSafeArea: true,
  builder: (_) => _RecoveryForm(state: state),
);

class _RecoveryForm extends StatefulWidget {
  const _RecoveryForm({required this.state});
  final AppState state;
  @override
  State<_RecoveryForm> createState() => _RecoveryFormState();
}
class _RecoveryFormState extends State<_RecoveryForm> {
  final pseudo = TextEditingController(), phone = TextEditingController();
  final password = TextEditingController(), confirm = TextEditingController();
  final form = GlobalKey<FormState>();
  Country country = Country.parse('BF');
  String? code, error;
  bool busy = false, visible = false;
  @override
  void dispose() { pseudo.dispose(); phone.dispose(); password.dispose(); confirm.dispose(); super.dispose(); }
  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() { busy = true; error = null; });
    try {
      if (code == null) {
        final result = await widget.state.api.recoverAccount(pseudo.text, '+${country.phoneCode}${phone.text}', country.countryCode);
        if (mounted) setState(() => code = result);
      } else {
        await widget.state.api.resetPassword(code!, password.text);
        if (mounted) { showToast(context, 'Mot de passe modifié. Vous pouvez vous connecter.', success: true); Navigator.pop(context); }
      }
    } catch (e) {
      if (mounted) setState(() => error = friendlyFailure(e, action: 'récupérer votre compte'));
    } finally { if (mounted) setState(() => busy = false); }
  }
  @override
  Widget build(BuildContext context) => SafeArea(child: SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(22, 8, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
    child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(code == null ? 'Retrouvez votre compte' : 'Nouveau mot de passe', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 18),
      if (code == null) ...[
        TextFormField(controller: pseudo, enabled: !busy, decoration: const InputDecoration(labelText: 'Nom d’utilisateur'),
          validator: (v) => (v ?? '').trim().isEmpty ? 'Saisissez votre pseudo.' : null),
        const SizedBox(height: 14),
        TextFormField(controller: phone, enabled: !busy, keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
          decoration: InputDecoration(labelText: 'Numéro de récupération', prefixIcon: TextButton(
            onPressed: busy ? null : () => showCountryPicker(context: context, showPhoneCode: true, onSelect: (v) => setState(() => country = v)),
            child: Text('${country.flagEmoji} +${country.phoneCode} ▾'))),
          validator: (v) => RegExp(r'^\d{4,14}$').hasMatch(v ?? '') ? null : 'Vérifiez votre numéro national.'),
      ] else ...[
        TextFormField(controller: password, enabled: !busy, obscureText: !visible,
          decoration: InputDecoration(labelText: 'Nouveau mot de passe', suffixIcon: IconButton(onPressed: () => setState(() => visible = !visible), icon: Icon(visible ? Icons.visibility_off : Icons.visibility))),
          validator: (v) => (v ?? '').length < 8 ? '8 caractères minimum.' : null),
        const SizedBox(height: 14),
        TextFormField(controller: confirm, enabled: !busy, obscureText: !visible,
          decoration: const InputDecoration(labelText: 'Confirmer le mot de passe'),
          validator: (v) => v != password.text ? 'Les mots de passe diffèrent.' : null),
      ],
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
      const SizedBox(height: 20),
      FilledButton(onPressed: busy ? null : submit, child: Text(busy ? 'Veuillez patienter…' : code == null ? 'Vérifier mes coordonnées' : 'Enregistrer')),
    ])),
  ));
}
