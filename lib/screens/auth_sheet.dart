import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'recovery_sheet.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/app_feedback.dart';
import '../services/app_state.dart';

Future<void> showAuthSheet(BuildContext context, AppState state, {required bool signup}) async {
  await showModalBottomSheet<void>(
    context: context, isScrollControlled: true, useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .52),
    builder: (_) => _AuthForm(state: state, signup: signup),
  );
}

class _AuthForm extends StatefulWidget {
  const _AuthForm({required this.state, required this.signup});
  final AppState state;
  final bool signup;
  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final _form = GlobalKey<FormState>();
  final _pseudo = TextEditingController();
  final _password = TextEditingController();
  final _phone = TextEditingController();
  late bool _signup = widget.signup;
  Country _country = Country.parse('BF');
  bool _busy = false;
  bool _visible = false;
  String? _error;

  @override
  void dispose() {
    _pseudo.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _switch(bool signup) {
    if (_busy || signup == _signup) return;
    setState(() { _signup = signup; _error = null; _visible = false; });
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    try {
      if (_signup) {
        await widget.state.signup(_pseudo.text.trim(), _password.text, '+${_country.phoneCode}${_phone.text}', phoneCountry: _country.countryCode);
      } else {
        await widget.state.login(_pseudo.text.trim(), _password.text);
      }
      if (!mounted) return;
      TextInput.finishAutofillContext();
      Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = friendlyFailure(error, action: _signup ? 'créer votre compte' : 'vous connecter'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: SafeArea(top: false, child: Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 20),
        child: AutofillGroup(child: Form(
          key: _form,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(8)))),
            const SizedBox(height: 18),
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset('assets/branding/icon.png', width: 44, height: 44)),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('FASOBIBLIO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                Text('Votre bibliothèque numérique', style: TextStyle(fontSize:12, color: AppColors.muted)),
              ])),
              IconButton(tooltip: 'Fermer', onPressed: _busy ? null : () => Navigator.pop(context), icon: const Icon(AppIcons.close)),
            ]),
            const SizedBox(height: 20),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Inscription')),
                ButtonSegment(value: false, label: Text('Connexion')),
              ],
              selected: {_signup}, showSelectedIcon: false,
              onSelectionChanged: _busy ? null : (values) => _switch(values.first),
            ),
            const SizedBox(height: 22),
            Text(_signup ? 'Créez votre espace' : 'Retrouvez votre espace', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(_signup ? 'Un compte pour retrouver vos achats et vos accès sur le site et dans l’application.' : 'Connectez-vous avec votre compte Fasobiblio.', style: const TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _pseudo, enabled: !_busy, autocorrect: false,
              autofillHints: const [AutofillHints.username],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Nom d’utilisateur', hintText: 'Votre pseudo', prefixIcon: Icon(AppIcons.user), errorMaxLines: 3),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) return 'Saisissez votre pseudo.';
                if (_signup && !RegExp(r'^[A-Za-z0-9_.-]{3,24}$').hasMatch(text)) return '3 à 24 caractères : lettres, chiffres, point, tiret ou underscore.';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _password, enabled: !_busy, obscureText: !_visible,
              autocorrect: false, enableSuggestions: false,
              autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
              textInputAction: _signup ? TextInputAction.next : TextInputAction.done,
              onFieldSubmitted: (_) { if (!_signup) _submit(); },
              decoration: InputDecoration(
                labelText: 'Mot de passe', hintText: _signup ? '8 caractères minimum' : 'Votre mot de passe',
                prefixIcon: const Icon(AppIcons.lock), errorMaxLines: 2,
                suffixIcon: IconButton(
                  tooltip: _visible ? 'Masquer le mot de passe' : 'Afficher le mot de passe',
                  onPressed: _busy ? null : () => setState(() => _visible = !_visible),
                  icon: Icon(_visible ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Saisissez votre mot de passe.';
                if (_signup && value.length < 8) return 'Utilisez au moins 8 caractères.';
                return null;
              },
            ),
            if (!_signup) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _busy ? null : () => showRecoverySheet(context, widget.state), child: const Text('Mot de passe oublié ?'))),
            if (_signup) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _phone, enabled: !_busy,
                keyboardType: TextInputType.phone, textInputAction: TextInputAction.done,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(15)],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(labelText: 'Numéro de récupération', hintText: 'Votre numéro', errorMaxLines: 2,
                  prefixIcon: TextButton(onPressed: _busy ? null : () => showCountryPicker(context: context, showPhoneCode: true, onSelect: (country) => setState(() => _country = country)), child: Text('${_country.flagEmoji} +${_country.phoneCode} ▾'))),
                validator: (value) => RegExp(r'^\d{6,14}$').hasMatch(value ?? '') ? null : 'Saisissez votre numéro national, sans indicatif.',
              ),
              const SizedBox(height: 7),
              const Text('Ce numéro sert à la récupération de votre compte.', style: TextStyle(fontSize:12, color: AppColors.muted)),
            ],
            if (_error != null) Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Semantics(liveRegion: true, child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12))),
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(_signup ? 'Créer mon compte' : 'Se connecter'),
            ),
            TextButton(
              onPressed: _busy ? null : () => _switch(!_signup),
              child: Text(_signup ? 'Déjà inscrit ? Se connecter' : 'Nouveau ici ? Créer un compte'),
            ),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Continuer comme invité')),
          ]),
        )),
      ),
    )),
  );
}
