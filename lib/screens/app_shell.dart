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

class AppShell extends StatefulWidget { const AppShell({super.key, required this.state}); final AppState state; @override State<AppShell> createState() => _AppShellState(); }
class _AppShellState extends State<AppShell> {
  int index = 0;
  void book(Book value) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: value, state: widget.state)));
  void assistant() => Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(api: widget.state.api)));
  @override Widget build(BuildContext context) {
    final pages = [HomeScreen(state: widget.state, onExplore: () => setState(() => index = 2), onBook: book), PremiumScreen(state: widget.state, onBook: book), ExploreScreen(state: widget.state, onBook: book, onAssistant: assistant), LibraryScreen(state: widget.state, onBook: book), ProfileScreen(state: widget.state, onAssistant: assistant)];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
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
    color: Colors.white,
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
    if (state.error != null && state.books.isEmpty) return Scaffold(body: SafeArea(child: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.cloud_off_rounded, size: 58, color: AppColors.muted), const SizedBox(height: 15), Text('Connexion impossible', style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 8), Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)), const SizedBox(height: 18), FilledButton.icon(onPressed: () => state.load(), icon: const Icon(Icons.refresh_rounded), label: const Text('Réessayer'))])))));
    return AppShell(state: state);
  }
}
