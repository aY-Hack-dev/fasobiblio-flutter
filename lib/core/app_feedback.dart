import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import '../services/app_state.dart';

const offlineMessage = 'Vous êtes en mode hors connexion. Veuillez vérifier votre connexion Internet.';

String friendlyFailure(Object error, {String action = 'effectuer cette opération'}) {
  if (error is SocketException || error is TimeoutException) return 'Nous n’avons pas pu $action. Vérifiez votre connexion Internet puis réessayez.';
  if (error is PlatformException) return 'Nous n’avons pas pu $action sur cet appareil. Fermez cette page puis réessayez.';
  final raw = error.toString().replaceFirst('Exception: ', '').toLowerCase();
  if (raw.contains('hors connexion') || raw.contains('internet') || raw.contains('socket') || raw.contains('timed out')) return offlineMessage;
  if (raw.contains('pseudo ou mot de passe')) return 'Pseudo ou mot de passe incorrect.';
  if (raw.contains('déjà utilisé')) return 'Ce pseudo est déjà utilisé.';
  if (raw.contains('numéro') && raw.contains('invalide')) return 'Le numéro renseigné n’est pas valide. Vérifiez-le puis réessayez.';
  if (raw.contains('quota')) return 'Votre quota de téléchargement est atteint. Consultez les offres Premium pour continuer.';
  return 'Nous n’avons pas pu $action. Vérifiez les informations saisies puis réessayez.';
}

void showToast(BuildContext context, String message, {bool success = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    content: Row(children: [Icon(success ? AppIcons.checkCircle : AppIcons.info, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message))]),
  ));
}

bool requireInternet(BuildContext context, AppState state) {
  if (!state.offline) return true;
  showToast(context, offlineMessage);
  return false;
}
