import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import 'assistant_screen.dart';
import 'book_detail_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'auth_sheet.dart';
import '../widgets/app_header.dart';

class AppShell extends StatefulWidget { const AppShell({super.key, required this.state}); final AppState state; @override State<AppShell> createState() => _AppShellState(); }
class _AppShellState extends State<AppShell> {
  int index = 0;
  void book(Book value) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: value, state: widget.state)));
  void assistant() => Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(state: widget.state)));
  void notifications() => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(state: widget.state)));
  @override Widget build(BuildContext context) {
    final pages = [HomeScreen(state: widget.state, onExplore: () => setState(() => index = 2), onBook: book), PremiumScreen(state: widget.state, onBook: book), ExploreScreen(state: widget.state, onBook: book, onAssistant: assistant), LibraryScreen(state: widget.state, onBook: book), ProfileScreen(state: widget.state, onAssistant: assistant, onLibrary: () => setState(() => index = 3), onNotifications: notifications)];
    return Scaffold(
      body: SafeArea(child: Column(children: [
        AppHeader(state: widget.state, onNotifications: notifications),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ])),
      bottomNavigationBar: _ResponsiveBottomNav(
        selectedIndex: index,
        libraryCount: widget.state.favorites.length + widget.state.later.length,
        onSelected: (value) => setState(() => index = value),
      ),
    );
  }
}

class _ResponsiveBottomNav extends StatelessWidget {
  const _ResponsiveBottomNav({
    required this.selectedIndex,
    required this.libraryCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int libraryCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    elevation: 10,
    shadowColor: const Color(0x22000000),
    child: SafeArea(
      top: false,
      child: LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 370;
        final items = <_NavItemData>[
          const _NavItemData('Accueil', Icons.home_outlined, Icons.home_rounded),
          const _NavItemData('Premium', Icons.workspace_premium_outlined, Icons.workspace_premium_rounded),
          const _NavItemData('Explorer', Icons.search_rounded, Icons.search_rounded),
          _NavItemData('Bibliothèque', Icons.local_library_outlined, Icons.local_library_rounded, badge: libraryCount),
          const _NavItemData('Profil', Icons.person_outline_rounded, Icons.person_rounded),
        ];
        return SizedBox(
          height: compact ? 68 : 72,
          child: Row(
            children: List.generate(items.length, (itemIndex) => Expanded(
              child: _BottomNavItem(
                data: items[itemIndex],
                selected: selectedIndex == itemIndex,
                compact: compact,
                onTap: () => onSelected(itemIndex),
              ),
            )),
          ),
        );
      }),
    ),
  );
}

class _NavItemData {
  const _NavItemData(this.label, this.icon, this.selectedIcon, {this.badge = 0});
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final int badge;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.data, required this.selected, required this.compact, required this.onTap});
  final _NavItemData data;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.muted;
    final icon = Icon(selected ? data.selectedIcon : data.icon, color: color, size: compact ? 24 : 26);
    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 3 : 5, 6, compact ? 3 : 5, 4),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: compact ? 13 : 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? AppColors.sky : Colors.transparent,
                borderRadius: BorderRadius.circular(22),
              ),
              child: data.badge > 0
                  ? Badge(label: Text(data.badge > 99 ? '99+' : '${data.badge}'), child: icon)
                  : icon,
            ),
            const SizedBox(height: 3),
            SizedBox(
              width: double.infinity,
              child: Text(
                data.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 10 : 11,
                  height: 1.05,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, required this.state}); final AppState state;
  @override Widget build(BuildContext context) {
    if (state.loading && state.books.isEmpty) return const Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Image(image: AssetImage('assets/branding/icon.png'), width: 105, height: 105), SizedBox(height: 18), Text.rich(TextSpan(children: [TextSpan(text: 'FASO', style: TextStyle(color: AppColors.ink)), TextSpan(text: 'BIBLIO', style: TextStyle(color: AppColors.blue))]), style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), SizedBox(height: 25), CircularProgressIndicator(), SizedBox(height: 11), Text('Chargement de votre bibliothèque…', style: TextStyle(fontSize: 11, color: AppColors.muted))])));
    if (!state.welcomeSeen) return WelcomeScreen(state: state);
    return AppShell(state: state);
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.state});
  final AppState state;

  Future<void> _auth(BuildContext context, {required bool signup}) async {
    await showAuthSheet(context, state, signup: signup);
    if (state.session != null && !state.session!.anonymous) await state.completeWelcome();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0B2C69), Color(0xFF1454D8), Color(0xFF082E91)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: SafeArea(child: LayoutBuilder(builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(26, 24, 26, 25),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 49),
          child: IntrinsicHeight(child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [Image.asset('assets/branding/icon.png', width: 54, height: 54), const SizedBox(width: 11), const Text('Fasobiblio', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900, color: Colors.white))]),
            const SizedBox(height: 8),
            const Text('Votre bibliothèque numérique partout,\nmême hors connexion.', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFFE6EDFF))),
            const Spacer(),
            Container(
              width: 260,
              height: 245,
              decoration: BoxDecoration(color: const Color(0x24FFFFFF), shape: BoxShape.circle, border: Border.all(color: const Color(0x2FFFFFFF))),
              child: Stack(alignment: Alignment.center, children: [
                Transform.rotate(angle: -.12, child: Container(width: 125, height: 175, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 22, offset: Offset(0, 12))]), child: const Icon(Icons.auto_stories_rounded, size: 70, color: AppColors.blue))),
                const Positioned(left: 13, bottom: 35, child: Icon(Icons.cloud_download_rounded, color: Colors.white, size: 42)),
                const Positioned(right: 17, top: 38, child: Icon(Icons.headphones_rounded, color: Colors.white, size: 39)),
              ]),
            ),
            const Spacer(),
            const Text('Bienvenue sur Fasobiblio', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Découvrez, lisez, téléchargez et sauvegardez vos documents préférés.', textAlign: TextAlign.center, style: TextStyle(height: 1.45, color: Color(0xFFE6EDFF))),
            const SizedBox(height: 22),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: state.completeWelcome, style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFFC928), foregroundColor: AppColors.navy), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Continuer directement'))),
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => _auth(context, signup: true), style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.navy), icon: const Icon(Icons.person_add_alt_1_rounded), label: const Text('Créer un compte'))),
            const SizedBox(height: 9),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () => _auth(context, signup: false), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white), minimumSize: const Size(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), icon: const Icon(Icons.login_rounded), label: const Text('Se connecter'))),
            const SizedBox(height: 13),
            const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shield_outlined, color: Color(0xFFCCD8F5), size: 15), SizedBox(width: 5), Text('Vos données sont protégées et confidentielles', style: TextStyle(fontSize: 10, color: Color(0xFFCCD8F5)))]),
          ])),
        ),
      ))),
    ),
  );
}
