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
          height: compact ? 62 : 66,
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
    final icon = Icon(selected ? data.selectedIcon : data.icon, color: color, size: compact ? 22 : 24);
    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.fromLTRB(compact ? 3 : 5, 5, compact ? 3 : 5, 3),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 15, vertical: 3),
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
                  fontSize: compact ? 9 : 10,
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
    if (state.loading && state.books.isEmpty) return const _LibraryLoadingScreen();
    return AppShell(state: state);
  }
}

class _LibraryLoadingScreen extends StatefulWidget {
  const _LibraryLoadingScreen();
  @override
  State<_LibraryLoadingScreen> createState() => _LibraryLoadingScreenState();
}

class _LibraryLoadingScreenState extends State<_LibraryLoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Stack(children: [
        Center(child: Image.asset('assets/branding/icon.png', width: 154, height: 154, fit: BoxFit.contain)),
        Positioned(
          left: 24,
          right: 24,
          bottom: 44,
          child: Column(children: [
            AnimatedBuilder(
              animation: controller,
              builder: (_, __) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(5, (index) {
                  final phase = (controller.value + index * .14) % 1;
                  final lift = phase < .5 ? phase * 2 : (1 - phase) * 2;
                  return Transform.translate(
                    offset: Offset(0, -5 * lift),
                    child: Container(
                      width: index == 2 ? 15 : 11,
                      height: (22 + (index % 3) * 7).toDouble(),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: index.isEven ? AppColors.blue : AppColors.ink,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              'Fasobiblio, le savoir, partout avec vous.',
              textAlign: TextAlign.center,
              style: AppTypography.display(size: 13, weight: FontWeight.w700, color: AppColors.ink),
            ),
          ]),
        ),
      ]),
    ),
  );
}
