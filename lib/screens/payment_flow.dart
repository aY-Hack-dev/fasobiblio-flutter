import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../core/app_feedback.dart';
import 'auth_sheet.dart';
import 'payment_webview_screen.dart';

Future<bool> _ensureAccount(BuildContext context, AppState state) async {
  if (state.session != null && !state.session!.anonymous) return true;
  final choice = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .52),
    builder: (sheetContext) {
      final dark = Theme.of(sheetContext).brightness == Brightness.dark;
      return SafeArea(
        top: false,
        child: Material(
          color: dark ? const Color(0xFF111B2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 44, height: 5, decoration: BoxDecoration(color: dark ? const Color(0xFF43516A) : const Color(0xFFD4DDEA), borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 22),
              Container(width: 64, height: 64, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(20)), child: const Icon(AppIcons.account, color: AppColors.blue, size: 32)),
              const SizedBox(height: 16),
              Text('Compte Fasobiblio requis', textAlign: TextAlign.center, style: AppTypography.display(size: 22, weight: FontWeight.w900, color: Theme.of(sheetContext).colorScheme.onSurface)),
              const SizedBox(height: 8),
              const Text('Connectez-vous pour sécuriser vos achats et retrouver votre abonnement sur tous vos appareils.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.55, color: AppColors.muted)),
              const SizedBox(height: 22),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(sheetContext, true), child: const Text('Créer un compte'))),
              const SizedBox(height: 8),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext, false), child: const Text('J’ai déjà un compte'))),
            ]),
          ),
        ),
      );
    },
  );
  if (choice == null || !context.mounted) return false;
  await showAuthSheet(context, state, signup: choice);
  return state.session != null && !state.session!.anonymous;
}

Future<String?> _askPhone(BuildContext context, {required String title, required String price}) async {
  final controller = TextEditingController();
  String? error;
  final result = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => StatefulBuilder(
      builder: (context, setState) => Container(
        padding: EdgeInsets.fromLTRB(22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 44, height: 5, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 18),
            const Icon(AppIcons.smartphone, color: AppColors.blue, size: 38),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 19)),
            const SizedBox(height: 16),
            TextField(controller: controller, autofocus: true, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Numéro Mobile Money', hintText: 'Ex : 70 12 34 56', prefixIcon: Icon(AppIcons.smartphone))),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: FilledButton.icon(icon: const Icon(AppIcons.lock), label: const Text('Continuer vers le paiement'), onPressed: () {
              final phone = controller.text.replaceAll(RegExp(r'\D'), '');
              if (!RegExp(r'^\d{8,10}$').hasMatch(phone)) { setState(() => error = 'Entrez un numéro valide de 8 à 10 chiffres.'); return; }
              Navigator.pop(sheetContext, phone);
            })),
            const SizedBox(height: 8),
            const Text('Orange Money et Moov Money • paiement sécurisé par MoneyFusion', textAlign: TextAlign.center, style: TextStyle(fontSize:12, color: AppColors.muted)),
          ]),
        ),
      ),
    ),
  );
  controller.dispose();
  return result;
}

Future<T?> _startPayment<T>(BuildContext context, Future<T> Function() action, {String label = 'Connexion au service de paiement…'}) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      icon: const SizedBox(width: 34, height: 34, child: CircularProgressIndicator(strokeWidth: 3)),
      title: const Text('Veuillez patienter'),
      content: Text(label, textAlign: TextAlign.center),
    ),
  );
  try { return await action(); }
  finally { if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); }
}

Future<bool> purchaseDocument(BuildContext context, AppState state, Book book) async {
  if (!requireInternet(context, state)) return false;
  if (!await _ensureAccount(context, state) || !context.mounted) return false;
  final phone = await _askPhone(context, title: book.title, price: '${book.price.toInt()} FCFA');
  if (phone == null || !context.mounted) return false;
  try {
    final payment = await _startPayment(context, () => state.api.startDocumentPayment(docId: book.id, phone: phone, pseudo: state.session!.pseudo));
    if (payment == null || payment['url'] == null || payment['url']!.isEmpty || !context.mounted) throw Exception('Lien de paiement indisponible.');
    final returned = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: payment['url']!))) == true;
    if (!returned || !context.mounted) return false;
    var unlocked = false;
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(icon: CircularProgressIndicator(), title: Text('Vérification du paiement'), content: Text('Activation de votre document en cours…')));
    for (var attempt = 0; attempt < 8 && !unlocked; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 2));
      try { unlocked = await state.api.checkAccess(book.id); } catch (_) {}
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    await state.refreshAccount();
    if (context.mounted) showToast(context, unlocked ? 'Paiement confirmé : document débloqué.' : 'Paiement reçu. L’activation apparaîtra dès sa confirmation.', success: unlocked);
    return unlocked;
  } catch (error) {
    if (context.mounted) showToast(context, friendlyFailure(error, action: 'finaliser cet achat'));
    return false;
  }
}

Future<bool> purchaseSubscription(BuildContext context, AppState state, Map<String, dynamic> offer) async {
  if (!requireInternet(context, state)) return false;
  if (!await _ensureAccount(context, state) || !context.mounted) return false;
  final id = '${offer['id'] ?? ''}';
  final nameValue = offer['name'];
  final name = nameValue is Map ? '${nameValue['fr'] ?? (nameValue.values.isNotEmpty ? nameValue.values.first : 'Premium')}' : '${nameValue ?? 'Premium'}';
  final priceValue = offer['price'];
  final price = priceValue is num ? priceValue.toInt() : int.tryParse('$priceValue') ?? 0;
  final phone = await _askPhone(context, title: 'Abonnement $name', price: '$price FCFA');
  if (phone == null || !context.mounted) return false;
  try {
    final payment = await _startPayment(context, () => state.api.startSubscriptionPayment(planId: id, phone: phone, pseudo: state.session!.pseudo));
    if (payment == null || payment['url'] == null || payment['url']!.isEmpty || !context.mounted) throw Exception('Lien de paiement indisponible.');
    final returned = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: payment['url']!))) == true;
    if (!returned || !context.mounted) return false;
    Map<String, dynamic>? subscription;
    showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const AlertDialog(icon: CircularProgressIndicator(), title: Text('Activation Premium'), content: Text('Confirmation de votre abonnement en cours…')));
    for (var attempt = 0; attempt < 8 && subscription == null; attempt++) {
      if (attempt > 0) await Future<void>.delayed(const Duration(seconds: 2));
      try { subscription = await state.api.mySubscription(); } catch (_) {}
    }
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    await state.refreshAccount();
    if (context.mounted) showToast(context, subscription != null ? 'Votre abonnement Premium est actif.' : 'Paiement reçu. Activation Premium en cours.', success: subscription != null);
    return subscription != null;
  } catch (error) {
    if (context.mounted) showToast(context, friendlyFailure(error, action: 'finaliser cet abonnement'));
    return false;
  }
}

Future<bool> makeDonation(BuildContext context, AppState state) async {
  if (!requireInternet(context, state)) return false;
  if (!await _ensureAccount(context, state) || !context.mounted) return false;
  final custom = TextEditingController();
  final phone = TextEditingController();
  int? selected;
  String? error;
  var busy = false;
  final payment = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .52),
    builder: (sheetContext) => StatefulBuilder(builder: (context, setState) {
      Future<void> submit() async {
        final parsed = int.tryParse(custom.text.trim());
        final amount = selected ?? parsed;
        final digits = phone.text.replaceAll(RegExp(r'\D'), '');
        if (amount == null || amount < 100) { setState(() => error = 'Choisissez un montant d’au moins 100 FCFA.'); return; }
        if (!RegExp(r'^\d{8,10}$').hasMatch(digits)) { setState(() => error = 'Entrez un numéro Mobile Money valide de 8 à 10 chiffres.'); return; }
        setState(() { busy = true; error = null; });
        try {
          final result = await state.api.startDonationPayment(amount: amount, phone: digits, pseudo: state.session!.pseudo);
          if (sheetContext.mounted) Navigator.pop(sheetContext, {'url': result['url'] ?? '', 'amount': amount});
        } catch (e) {
          if (sheetContext.mounted) setState(() { busy = false; error = friendlyFailure(e, action: 'démarrer le don'); });
        }
      }
      final dark = Theme.of(context).brightness == Brightness.dark;
      return SafeArea(
        top: false,
        child: Material(
          color: dark ? const Color(0xFF111B2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          clipBehavior: Clip.antiAlias,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(22, 10, 22, MediaQuery.viewInsetsOf(context).bottom + 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 44, height: 5, decoration: BoxDecoration(color: dark ? const Color(0xFF43516A) : const Color(0xFFD4DDEA), borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 18),
              Row(children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: const Color(0xFFFFEEF2), borderRadius: BorderRadius.circular(15)), child: const Icon(AppIcons.heart, color: Color(0xFFE11D48))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Faire un don', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 3), const Text('Chaque contribution aide à maintenir Fasobiblio accessible.', style: TextStyle(fontSize:12, color: AppColors.muted))])),
              ]),
              const SizedBox(height: 18),
              Wrap(spacing: 8, runSpacing: 8, children: [500, 1000, 2500].map((amount) => ChoiceChip(label: Text('$amount F'), selected: selected == amount, onSelected: busy ? null : (_) => setState(() { selected = amount; custom.clear(); error = null; }))).toList()),
              const SizedBox(height: 14),
              TextField(controller: custom, enabled: !busy, keyboardType: TextInputType.number, onChanged: (v) { if (v.isNotEmpty) setState(() { selected = null; error = null; }); }, decoration: const InputDecoration(labelText: 'Ou montant libre (FCFA)', hintText: 'Ex : 750')),
              const SizedBox(height: 12),
              TextField(controller: phone, enabled: !busy, keyboardType: TextInputType.phone, onChanged: (_) { if (error != null) setState(() => error = null); }, decoration: const InputDecoration(labelText: 'Numéro Mobile Money', hintText: 'Ex : 70 12 34 56', prefixIcon: Icon(AppIcons.smartphone))),
              if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Color(0xFFB91C1C), fontSize:12, fontWeight: FontWeight.w700))),
              const SizedBox(height: 18),
              SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : submit, icon: busy ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(AppIcons.heart), label: Text(busy ? 'Connexion au paiement…' : 'Continuer'))),
            ]),
          ),
        ),
      );
    }),
  );
  custom.dispose(); phone.dispose();
  if (payment == null || !context.mounted) return false;
  final url = '${payment['url'] ?? ''}';
  if (url.isEmpty) { showToast(context, 'Lien de paiement indisponible.'); return false; }
  final returned = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => PaymentWebViewScreen(url: url))) == true;
  if (returned && context.mounted) showToast(context, 'Merci pour votre soutien à Fasobiblio ❤️', success: true);
  return returned;
}
