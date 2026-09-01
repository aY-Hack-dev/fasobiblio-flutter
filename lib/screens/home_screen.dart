import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/brand_header.dart';
import '../widgets/section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onExplore, required this.onBook});
  final AppState state; final VoidCallback onExplore; final ValueChanged<Book> onBook;

  @override
  Widget build(BuildContext context) {
    final popular = [...state.books]..sort((a, b) => b.views.compareTo(a.views));
    final recent = [...state.books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final categories = state.books.map((book) => book.category).toSet().take(10).toList();
    return RefreshIndicator(
      onRefresh: () => state.load(refresh: true),
      child: CustomScrollView(slivers: [
        const SliverToBoxAdapter(child: BrandHeader()),
        SliverToBoxAdapter(child: _Hero(count: state.books.length, categories: categories.length, reads: state.books.fold(0, (sum, book) => sum + book.views), onExplore: onExplore)),
        const SliverToBoxAdapter(child: SectionTitle('Rayons populaires')),
        SliverToBoxAdapter(child: SizedBox(height: 48, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 20), scrollDirection: Axis.horizontal, itemCount: categories.length, separatorBuilder: (_, __) => const SizedBox(width: 9), itemBuilder: (_, i) => Container(padding: const EdgeInsets.symmetric(horizontal: 15), alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(14)), child: Text(categoryLabel(categories[i]), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.navy)))))),
        SliverToBoxAdapter(child: _Shelf(title: 'Les plus lus', books: popular.take(10).toList(), state: state, onBook: onBook)),
        SliverToBoxAdapter(child: _StudyCard(onTap: onExplore)),
        SliverToBoxAdapter(child: _Shelf(title: 'Nouveautés', books: recent.take(10).toList(), state: state, onBook: onBook)),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.count, required this.categories, required this.reads, required this.onExplore});
  final int count, categories, reads; final VoidCallback onExplore;
  @override Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF102A43), Color(0xFF1D3F6E)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x25102A43), blurRadius: 24, offset: Offset(0, 12))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('APPRENDRE • COMPRENDRE • RÉUSSIR', style: TextStyle(fontSize: 9, letterSpacing: 1.25, fontWeight: FontWeight.w900, color: Color(0xFFAFC4FF))),
      const SizedBox(height: 12), const Text('Le savoir, partout avec vous.', style: TextStyle(fontSize: 29, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white)),
      const SizedBox(height: 10), const Text('Des ouvrages, cours et ressources sélectionnés pour les apprenants du Faso.', style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xFFD5DCE7))),
      const SizedBox(height: 20), Row(children: [_HeroStat('$count', 'documents'), _HeroStat('$categories', 'rayons'), _HeroStat(_compact(reads), 'lectures')]),
      const SizedBox(height: 20), SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onExplore, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue), icon: const Icon(Icons.search_rounded), label: const Text('Explorer le catalogue'))),
    ]),
  );
  static String _compact(int value) => value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
}

class _HeroStat extends StatelessWidget {
  const _HeroStat(this.value, this.label); final String value, label;
  @override Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Colors.white)), Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFFBFC9D8)))]));
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.books, required this.state, required this.onBook});
  final String title; final List<Book> books; final AppState state; final ValueChanged<Book> onBook;
  @override Widget build(BuildContext context) => Column(children: [SectionTitle(title, action: 'Voir tout'), SizedBox(height: 304, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: books.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => BookCard(book: books[i], favorite: state.favorites.contains(books[i].id), onTap: () => onBook(books[i]))))]);
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.onTap}); final VoidCallback onTap;
  @override Widget build(BuildContext context) => Container(margin: const EdgeInsets.fromLTRB(16, 27, 16, 0), padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: const Color(0xFFFFF8E8), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1D99E))), child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.psychology_alt_rounded, color: AppColors.gold)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Besoin d’un coup de pouce ?', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)), SizedBox(height: 3), Text('L’assistant Fasobiblio vous guide dans vos recherches.', style: TextStyle(fontSize: 11, color: AppColors.muted))])), IconButton(onPressed: onTap, icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.gold))]));
}
