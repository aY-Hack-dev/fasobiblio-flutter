import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../core/app_feedback.dart';
import 'auth_sheet.dart';
import 'payment_webview_screen.dart';

Future<bool> _ensureAccount(BuildContext context, AppState state) async {
  if (state.session != null && !state.session!.anonymous) return true;
  final create = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.account_circle_rounded, color: AppColors.blue, size: 40),
      title: const Text('Compte Fasobiblio requis'),
      content: const Text('Connectez-vous pour conserver vos achats et votre abonnement sur tous vos appareils.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Connexion')),
        FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Créer un compte')),
      ],
    ),
  );
  if (create == null || !context.mounted) return false;
  await showAuthSheet(context, state, signup: create);
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
            const Icon(Icons.mobile_friendly_rounded, color: AppColors.blue, size: 38),
            const SizedBox(height: 10),
            Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 5),
            Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.gold, fontSize: 19)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Numéro Mobile Money', hintText: 'Ex : 70 12 34 56', prefixIcon: Icon(Icons.phone_android_rounded)),
            ),
            if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12))),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.lock_rounded),
                label: const Text('Continuer vers le paiement'),
                onPressed: () {
                  final phone = controller.text.replaceAll(RegExp(r'\D'), '');
                  if (!RegExp(r'^\d{8,10}$').hasMatch(phone)) {
                    setState(() => error = 'Entrez un numéro valide de 8 à 10 chiffres.');
                    return;
                  }
                  Navigator.pop(sheetContext, phone);
                },
              ),
            ),
            const SizedBox(height: 8),
            const Text('Orange Money et Moov Money • paiement sécurisé par MoneyFusion', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ]),
        ),
      ),
    ),
  );
  controller.dispose();
  return result;
}

Future<T?> _startPayment<T>(BuildContext context, Future<T> Function() action) async {
  showDialog<void>(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
  try {
    return await action();
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
}

Future<bool> purchaseDocument(BuildContext context, AppState state, Book book) async {
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
