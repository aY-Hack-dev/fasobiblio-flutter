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
    return Scaffold(body: SafeArea(child: IndexedStack(index: index, children: pages)), bottomNavigationBar: NavigationBar(selectedIndex: index, onDestinationSelected: (value) => setState(() => index = value), destinations: [const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'), const NavigationDestination(icon: Icon(Icons.workspace_premium_outlined), selectedIcon: Icon(Icons.workspace_premium_rounded), label: 'Premium'), const NavigationDestination(icon: Icon(Icons.search_rounded), label: 'Explorer'), NavigationDestination(icon: Badge(isLabelVisible: widget.state.favorites.isNotEmpty || widget.state.later.isNotEmpty, label: Text('${widget.state.favorites.length + widget.state.later.length}'), child: const Icon(Icons.local_library_outlined)), selectedIcon: const Icon(Icons.local_library_rounded), label: 'Bibliothèque'), const NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profil')]));
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
