import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/app_feedback.dart';
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
import '../widgets/app_background.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  DateTime? lastBackPress;

  void book(Book value) => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: value, state: widget.state)));
  void assistant() => Navigator.push(context, MaterialPageRoute(builder: (_) => AssistantScreen(state: widget.state)));
  void notifications() => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen(state: widget.state)));

  void handleBack() {
    if (index != 0) {
      setState(() => index = 0);
      return;
    }
    final now = DateTime.now();
    if (lastBackPress == null || now.difference(lastBackPress!) > const Duration(seconds: 2)) {
      lastBackPress = now;
      showToast(context, 'Cliquez à nouveau pour quitter Fasobiblio.');
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(state: widget.state, onExplore: () => setState(() => index = 2), onBook: book),
      PremiumScreen(state: widget.state, onBook: book),
      ExploreScreen(state: widget.state, onBook: book, onAssistant: assistant),
      LibraryScreen(state: widget.state, onBook: book),
      ProfileScreen(
        state: widget.state,
        onAssistant: assistant,
        onLibrary: () => setState(() => index = 3),
        onNotifications: notifications,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      child: Scaffold(
        extendBody: true,
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: AppHeader(state: widget.state, onNotifications: notifications),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: IndexedStack(index: index, children: pages),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _FloatingBottomNav(
          selectedIndex: index,
          libraryCount: widget.state.favorites.length + widget.state.later.length,
          onSelected: (value) => setState(() => index = value),
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({required this.selectedIndex, required this.libraryCount, required this.onSelected});

  final int selectedIndex;
  final int libraryCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 370;
    final items = <_NavItemData>[
      const _NavItemData('Accueil', AppIcons.home),
      const _NavItemData('Premium', AppIcons.premium, premium: true),
      const _NavItemData('Explorer', AppIcons.search),
      _NavItemData('Bibliothèque', AppIcons.library, badge: libraryCount),
      const _NavItemData('Profil', AppIcons.user),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Container(
            height: compact ? 66 : 72,
            decoration: BoxDecoration(
              color: const Color(0xF7112952),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: .10)),
              boxShadow: const [
                BoxShadow(color: Color(0x3506172F), blurRadius: 28, offset: Offset(0, 12)),
                BoxShadow(color: Color(0x151860F0), blurRadius: 16, offset: Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Row(
                children: List.generate(
                  items.length,
                  (itemIndex) => Expanded(
                    child: _BottomNavItem(
                      data: items[itemIndex],
                      selected: selectedIndex == itemIndex,
                      compact: compact,
                      onTap: () => onSelected(itemIndex),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  const _NavItemData(this.label, this.icon, {this.badge = 0, this.premium = false});
  final String label;
  final IconData icon;
  final int badge;
  final bool premium;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({required this.data, required this.selected, required this.compact, required this.onTap});

  final _NavItemData data;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = data.premium ? const Color(0xFFFFD166) : Colors.white;
    final idleColor = data.premium ? const Color(0xFFCEB268) : const Color(0xFFA7B5C9);
    final iconColor = selected ? selectedColor : idleColor;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: selected ? (compact ? 43 : 48) : 35,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? (data.premium ? const Color(0x28FFD166) : const Color(0x2B4B8DFF))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: selected ? Border.all(color: iconColor.withValues(alpha: .18)) : null,
                ),
                child: Center(
                  child: data.badge > 0
                      ? Badge(
                          backgroundColor: AppColors.blue,
                          textColor: Colors.white,
                          label: Text(data.badge > 99 ? '99+' : '${data.badge}'),
                          child: Icon(data.icon, color: iconColor, size: compact ? 20 : 22),
                        )
                      : Icon(data.icon, color: iconColor, size: compact ? 20 : 22),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: compact ? 8 : 9,
                  height: 1,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
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
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-.2, -.25),
                      radius: 1.1,
                      colors: [Color(0xFF1758CF), AppColors.navy],
                    ),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 178,
                  height: 178,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(42),
                    boxShadow: const [BoxShadow(color: Color(0x45000000), blurRadius: 30, offset: Offset(0, 18))],
                  ),
                  child: Image.asset('assets/branding/icon.png', fit: BoxFit.contain),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 48,
                child: Column(
                  children: [
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
                                color: index.isEven ? Colors.white : const Color(0xFF7FA7FF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Fasobiblio, le savoir, partout avec vous.',
                      textAlign: TextAlign.center,
                      style: AppTypography.display(size: 14, weight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
