import 'package:flutter/material.dart';

import '../core/app_feedback.dart';
import '../services/push_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  final service = PushService.instance;
  bool busy = false;
  Future<void> change(Future<void> Function() action) async {
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showToast(
          context,
          friendlyFailure(e, action: 'modifier vos notifications'),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: service,
    builder: (context, _) => Scaffold(
      appBar: AppBar(title: const Text('Préférences de notification')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Notifications push'),
            subtitle: Text(
              service.available
                  ? 'Recevoir les actualités et confirmations de Fasobiblio.'
                  : 'Les notifications push ne sont pas disponibles dans cette version.',
            ),
            value: service.enabled && service.available,
            onChanged: busy || !service.available
                ? null
                : (value) => change(() => service.setEnabled(value)),
          ),
          if (service.enabled && service.available)
            ListTile(
              leading: Icon(
                service.registered
                    ? Icons.check_circle_outline
                    : Icons.info_outline,
              ),
              title: Text(
                service.registered
                    ? 'Téléphone enregistré'
                    : 'Enregistrement à confirmer',
              ),
              subtitle: Text(
                service.registrationError ??
                    (service.registered
                        ? 'Le serveur a confirmé votre inscription aux notifications.'
                        : 'Vérifiez la connexion au service de notifications.'),
              ),
              trailing: service.registered
                  ? null
                  : TextButton(
                      onPressed: busy
                          ? null
                          : () => change(service.retryRegistration),
                      child: const Text('Réessayer'),
                    ),
            ),
          for (final item in PushService.categories.entries)
            SwitchListTile(
              title: Text(item.value),
              value: service.preferences[item.key] == true,
              onChanged: busy || !service.enabled || !service.available
                  ? null
                  : (value) =>
                        change(() => service.setCategory(item.key, value)),
            ),
          const Divider(),
          SwitchListTile(
            title: const Text('Rappel quotidien de lecture'),
            subtitle: const Text(
              'Un rappel discret, même sans connexion Internet. Son horaire peut varier selon l’appareil.',
            ),
            value: service.reminders,
            onChanged: busy || !service.initialized
                ? null
                : (value) => change(() => service.setReminders(value)),
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}
