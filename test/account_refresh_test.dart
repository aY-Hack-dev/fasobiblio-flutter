import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fasobiblio/models/app_notification.dart';
import 'package:fasobiblio/screens/auth_sheet.dart';
import 'package:fasobiblio/screens/app_shell.dart';
import 'package:fasobiblio/screens/assistant_screen.dart';
import 'package:fasobiblio/widgets/document_skeleton.dart';
import 'package:fasobiblio/screens/notifications_screen.dart';
import 'package:fasobiblio/screens/profile_screen.dart';
import 'package:fasobiblio/services/app_state.dart';
import 'package:fasobiblio/services/fasobiblio_api.dart';
import 'package:fasobiblio/services/local_store.dart';

class TestState extends AppState {
  TestState() : super(FasobiblioApi(), LocalStore());
  int loginCalls = 0;
  @override
  Future<void> login(String pseudo, String password) async { loginCalls++; }
  @override
  Future<void> setThemeMode(String value) async { themeMode = value; notifyListeners(); }
  @override
  Future<void> markNotificationRead(String id) async { notificationReads.add(id); notifyListeners(); }
}

void main() {
  testWidgets('Assistant tables do not squeeze surrounding paragraphs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox(width: 300, child: AssistantMessageBody(
      text: 'Une réponse lisible.\n\n| Sujet | Explication |\n| --- | --- |\n| Lecture | Un contenu suffisamment long pour vérifier le retour à la ligne. |\n\nConclusion lisible.',
    )))));
    expect(find.text('Une réponse lisible.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('First offline launch retains navigation and guest profile', (tester) async {
    final state = TestState()..offline = true;
    await tester.pumpWidget(MaterialApp(home: StartupScreen(state: state)));
    expect(find.byType(DocumentSkeleton), findsWidgets);
    expect(find.text('Que voulez-vous lire aujourd’hui ?'), findsOneWidget);
    await tester.tap(find.text('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Lecteur invité'), findsOneWidget);
    expect(find.byType(DocumentSkeleton), findsNothing);
    expect(find.text('Apparence'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Profile exposes all three appearance modes', (tester) async {
    final state = TestState();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ProfileScreen(
      state: state, onAssistant: () {}, onLibrary: () {}, onNotifications: () {},
    ))));
    expect(find.text('Lecteur invité'), findsOneWidget);
    expect(find.text('Système'), findsOneWidget);
    await tester.tap(find.text('Sombre'));
    expect(state.themeMode, 'dark');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Auth validates fields and allows existing shorter passwords', (tester) async {
    final state = TestState();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: Builder(builder: (context) => TextButton(
      onPressed: () => showAuthSheet(context, state, signup: false), child: const Text('Ouvrir'),
    )))));
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pumpAndSettle();
    expect(find.text('Saisissez votre pseudo.'), findsOneWidget);
    expect(state.loginCalls, 0);
    await tester.enterText(find.byType(TextFormField).at(0), 'lecteur');
    await tester.enterText(find.byType(TextFormField).at(1), 'ancien');
    await tester.tap(find.widgetWithText(FilledButton, 'Se connecter'));
    await tester.pumpAndSettle();
    expect(state.loginCalls, 1);
  });

  testWidgets('Unread filter reacts immediately when a notification is opened', (tester) async {
    final state = TestState();
    state.notifications = [
      AppNotification(id: '1', title: 'Nouveau document', message: 'Un nouveau cours est disponible.',
        createdAt: DateTime.now().millisecondsSinceEpoch, icon: 'fa-book', color: ''),
    ];
    await tester.pumpWidget(MaterialApp(home: NotificationsScreen(state: state)));
    await tester.tap(find.text('Non lues (1)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouveau document'));
    await tester.pumpAndSettle();
    expect(state.unreadNotifications, 0);
    Navigator.of(tester.element(find.byType(SelectableText))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Vous êtes à jour !'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
