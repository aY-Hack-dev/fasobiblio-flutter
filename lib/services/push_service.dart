import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../screens/notifications_screen.dart';
import '../screens/server_summary_screen.dart';
import 'app_state.dart';

@pragma('vm:entry-point')
Future<void> handleBackgroundPush(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class PushService extends ChangeNotifier {
  PushService._();
  static final instance = PushService._();
  static const categories = {
    'summary': 'Résumés prêts',
    'documents': 'Nouveaux documents',
    'admin': 'Annonces de Fasobiblio',
    'recommendations': 'Suggestions de lecture',
    'payment': 'Achats et abonnements',
  };
  final local = FlutterLocalNotificationsPlugin();
  final preferences = <String, bool>{
    for (final key in categories.keys) key: true,
  };
  bool available = false,
      enabled = false,
      reminders = false,
      initialized = false,
      prompting = false;
  AppState? state;
  GlobalKey<NavigatorState>? navigator;
  String? token, bindingUid;
  bool registered = false;
  String? registrationError;
  Map<String, dynamic>? pendingOpen;
  Future<void>? setup;
  Future<void> initialize(AppState value, GlobalKey<NavigatorState> key) =>
      setup ??= _initialize(value, key);
  Future<void> _initialize(
    AppState value,
    GlobalKey<NavigatorState> key,
  ) async {
    state = value;
    navigator = key;
    try {
      final saved = await value.store.loadJson('notifications.preferences');
      if (saved is Map) {
        enabled = saved['enabled'] == true;
        reminders = saved['reminders'] == true;
        for (final category in categories.keys) {
          preferences[category] = saved[category] != false;
        }
      }
      await local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('ic_notification'),
        ),
        onDidReceiveNotificationResponse: (response) {
          try {
            open(
              Map<String, dynamic>.from(jsonDecode(response.payload ?? '{}')),
            );
          } catch (_) {
            open({});
          }
        },
      );
      try {
        await Firebase.initializeApp();
        available = true;
        FirebaseMessaging.onBackgroundMessage(handleBackgroundPush);
        FirebaseMessaging.onMessage.listen((message) {
          if (!enabled ||
              (message.data['uid'] != null &&
                  message.data['uid'] != state?.session?.uid)) {
            return;
          }
          state?.refreshNotifications();
          final category = message.data['category'] ?? 'admin';
          if (preferences[category] == false) return;
          local.show(
            message.messageId.hashCode & 0x7fffffff,
            message.notification?.title ?? 'Fasobiblio',
            message.notification?.body,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'fasobiblio_general',
                'Notifications Fasobiblio',
                importance: Importance.defaultImportance,
              ),
            ),
            payload: jsonEncode(message.data),
          );
        });
        FirebaseMessaging.onMessageOpenedApp.listen(
          (message) => open(message.data),
        );
        FirebaseMessaging.instance.onTokenRefresh.listen((next) {
          token = next;
          sync();
        });
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (initial != null) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => open(initial.data),
          );
        }
        if (enabled) {
          token = await FirebaseMessaging.instance.getToken();
          await sync();
        }
      } catch (_) {
        available = false;
      }
    } catch (_) {
      /* Notification setup never blocks the library. */
    }
    initialized = true;
    value.addListener(_considerPrompt);
    _considerPrompt();
    notifyListeners();
  }

  Future<void> _considerPrompt() async {
    if (pendingOpen != null &&
        state?.loading == false &&
        (pendingOpen!['uid'] == null ||
            pendingOpen!['uid'] == state?.session?.uid)) {
      final data = pendingOpen!;
      pendingOpen = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => open(data));
    }
    final uid = state?.session?.uid;
    if (available && enabled && uid != null && uid != bindingUid) {
      bindingUid = uid;
      try {
        token = await FirebaseMessaging.instance.getToken();
        await sync();
      } catch (_) {}
    }
    if (!available ||
        prompting ||
        state == null ||
        state!.loading ||
        !state!.welcomeSeen) {
      return;
    }
    prompting = true;
    final asked = await state!.store.loadJson('notifications.permissionAsked');
    if (asked == true) return;
    final context = navigator?.currentContext;
    if (context == null || !context.mounted) {
      prompting = false;
      return;
    }
    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined),
        title: const Text('Gardez le fil de vos lectures'),
        content: const Text(
          'Recevez vos résumés prêts, les nouveautés et les annonces de Fasobiblio. Vous pourrez choisir les notifications dans votre profil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Plus tard'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
    await state!.store.saveJson('notifications.permissionAsked', true);
    if (accept == true) await setEnabled(true);
  }

  Future<void> save() async {
    await state?.store.saveJson('notifications.preferences', {
      'enabled': enabled,
      'reminders': reminders,
      ...preferences,
    });
    notifyListeners();
  }

  Future<void> setEnabled(bool value) async {
    if (!available) return;
    if (value) {
      final permission = await FirebaseMessaging.instance.requestPermission();
      enabled =
          permission.authorizationStatus == AuthorizationStatus.authorized ||
          permission.authorizationStatus == AuthorizationStatus.provisional;
      if (enabled) {
        await FirebaseMessaging.instance.setAutoInitEnabled(true);
        token = await FirebaseMessaging.instance.getToken();
      }
    } else {
      enabled = false;
      await sync();
      await FirebaseMessaging.instance.setAutoInitEnabled(false);
      await FirebaseMessaging.instance.deleteToken();
      token = null;
    }
    await save();
    await sync();
  }

  Future<void> setCategory(String key, bool value) async {
    preferences[key] = value;
    await save();
    await sync();
  }

  Future<void> retryRegistration() async {
    if (!available || !enabled) return;
    try {
      token = await FirebaseMessaging.instance.getToken();
      await sync();
    } catch (_) {
      registered = false;
      registrationError = 'Impossible de préparer les notifications. Réessayez avec une connexion Internet.';
      notifyListeners();
    }
  }

  Future<void> sync() async {
    final account = state;
    final uid = account?.session?.uid;
    final deviceToken = token;
    if (deviceToken == null || account == null || uid == null) {
      registered = false;
      registrationError = uid == null
          ? 'Connectez-vous pour recevoir les notifications.'
          : 'Le téléphone n’est pas encore enregistré. Réessayez.';
      notifyListeners();
      return;
    }
    try {
      final response = await account.api.authenticated(
        '/api/mobile/push-token',
        method: 'POST',
        body: {
          'token': deviceToken,
          'enabled': enabled,
          'categories': preferences,
        },
      );
      if (state?.session?.uid != uid || token != deviceToken) return;
      if (response['success'] != true) {
        throw StateError('Registration was not confirmed');
      }
      registered = enabled;
      registrationError = null;
    } catch (_) {
      if (state?.session?.uid != uid || token != deviceToken) return;
      registered = false;
      registrationError = 'Le serveur n’a pas confirmé l’enregistrement. Les notifications push ne sont pas encore prêtes.';
    }
    notifyListeners();
  }

  Future<void> detachAccount() async {
    registered = false;
    registrationError = null;
    if (token == null || state == null) return;
    try {
      await state!.api.authenticated(
        '/api/mobile/push-token',
        method: 'POST',
        body: {'token': token, 'enabled': false, 'categories': preferences},
      );
    } catch (_) {}
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
    token = null;
  }

  Future<void> setReminders(bool value) async {
    if (value) {
      final granted = await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (granted != true) return;
      await local.periodicallyShow(
        7310,
        'Un moment pour lire ?',
        'Retrouvez votre prochaine lecture dans Fasobiblio.',
        RepeatInterval.daily,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'fasobiblio_reading',
            'Rappels de lecture',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: '{}',
      );
    } else {
      await local.cancel(7310);
    }
    reminders = value;
    await save();
  }

  void open(Map<String, dynamic> data) {
    final current = state, nav = navigator?.currentState;
    if (current == null || nav == null) return;
    final uid = data['uid'];
    if (current.loading || (uid != null && uid != current.session?.uid)) {
      pendingOpen = data;
      return;
    }
    if (data['summaryId'] is String) {
      nav.push(
        MaterialPageRoute(
          builder: (_) =>
              ServerSummaryScreen(state: current, jobId: data['summaryId']),
        ),
      );
    } else {
      nav.push(
        MaterialPageRoute(builder: (_) => NotificationsScreen(state: current)),
      );
    }
  }
}
