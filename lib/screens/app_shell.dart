import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/app_background.dart';
import '../widgets/app_header.dart';
import 'assistant_screen.dart';
import 'book_detail_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'notifications_screen.dart';
import 'premium_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.state});
  final AppState state;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  DateTime? lastBackPress;

  void book(Book value) {
    widget.state.markDocumentOpened(value.id);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailScreen(book: value, state: widget.state),
      ),
    );
  }

  void assistant() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AssistantScreen(state: widget.state)),
      );

  void notifications() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NotificationsScreen(state: widget.state),
        ),
      );

  void handleBack() {
    if (index != 0) {
      setState(() => index = 0);
      return;
    }
    final now = DateTime.now();
    if (lastBackPress == null ||
        now.difference(lastBackPress!) > const Duration(seconds: 2)) {
      lastBackPress = now;
      showToast(context, 'Cliquez à nouveau pour quitter Fasobiblio.');
      return;
    }
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        state: widget.state,
        onExplore: () => setState(() => index = 2),
        onAssistant: assistant,
        onBook: book,
        onNotifications: notifications,
      ),
      PremiumScreen(state: widget.state, onBook: book),
      ExploreScreen(
        state: widget.state,
        onBook: book,
        onAssistant: assistant,
      ),
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
        body: AppBackground(
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                AppHeader(
                  state: widget.state,
                  onNotifications: notifications,
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
        bottomNavigationBar: _StandardBottomNav(
          selectedIndex: index,
          libraryCount:
              widget.state.favorites.length + widget.state.later.length,
          onSelected: (value) => setState(() => index = value),
        ),
      ),
    );
  }
}

class _StandardBottomNav extends StatelessWidget {
  const _StandardBottomNav({
    required this.selectedIndex,
    required this.libraryCount,
    required this.onSelected,
  });

  final int selectedIndex;
  final int libraryCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      const _NavItemData('Accueil', AppIcons.home),
      const _NavItemData('Premium', AppIcons.premium, premium: true),
      const _NavItemData('Explorer', AppIcons.search),
      _NavItemData('Bibliothèque', AppIcons.library, badge: libraryCount),
      const _NavItemData('Profil', AppIcons.user),
    ];
    final navColor = dark ? const Color(0xFF111B2C) : const Color(0xFFF4F7FF);

    return Material(
      color: navColor,
      elevation: 14,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: List.generate(
              items.length,
              (i) => Expanded(
                child: _BottomNavItem(
                  data: items[i],
                  selected: selectedIndex == i,
                  dark: dark,
                  onTap: () => onSelected(i),
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
  const _NavItemData(
    this.label,
    this.icon, {
    this.badge = 0,
    this.premium = false,
  });

  final String label;
  final IconData icon;
  final int badge;
  final bool premium;
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.data,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final _NavItemData data;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = data.premium ? AppColors.gold : AppColors.blue;
    final color = selected
        ? selectedColor
        : (dark ? const Color(0xFF9AA8BC) : AppColors.muted);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 7, 3, 5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 25,
              child: Center(
                child: data.badge > 0
                    ? Badge(
                        backgroundColor: AppColors.blue,
                        label: Text(data.badge > 99 ? '99+' : '${data.badge}'),
                        child: Icon(data.icon, color: color, size: 22),
                      )
                    : Icon(data.icon, color: color, size: 22),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 18 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: selectedColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) => AppShell(state: state);
}
