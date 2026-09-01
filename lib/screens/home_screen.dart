import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/section.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onExplore, required this.onBook});
  final AppState state;
  final VoidCallback onExplore;
  final ValueChanged<Book> onBook;

  @override
  Widget build(BuildContext context) {
    final popular = [...state.books]..sort((a, b) => b.views.compareTo(a.views));
    final recent = [...state.books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final premium = state.books.where((book) => book.isPremium).toList();
    final categories = state.books.map((book) => book.category).where((value) => value.isNotEmpty).toSet().take(10).toList();
    final featured = popular.isEmpty ? null : popular.first;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _Intro(onExplore: onExplore)),
      if (featured != null) SliverToBoxAdapter(child: _Featured(book: featured, count: state.books.length, onTap: () => onBook(featured))),
      if (state.books.isEmpty) const SliverToBoxAdapter(child: _FirstOfflineWelcome()),
      if (categories.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionTitle('Explorer les rayons')),
        SliverToBoxAdapter(child: _Categories(values: categories, onExplore: onExplore)),
      ],
      if (popular.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Populaires maintenant', books: popular.take(10).toList(), state: state, onBook: onBook)),
      if (recent.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Nouveautés', books: recent.take(10).toList(), state: state, onBook: onBook)),
      if (premium.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Sélection Premium', books: premium.take(10).toList(), state: state, onBook: onBook)),
      SliverToBoxAdapter(child: _StudyCard(onTap: onExplore)),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ]);
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Bonjour, bonne lecture 👋🏽', style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 5),
      const Text('Découvrez le document qui vous fera avancer.', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 16),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onExplore,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .55)), borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [Icon(Icons.search_rounded, color: AppColors.blue), SizedBox(width: 11), Expanded(child: Text('Rechercher un livre, un cours…', style: TextStyle(color: AppColors.muted))), Icon(Icons.tune_rounded, size: 20, color: AppColors.muted)]),
          ),
        ),
      ),
    ]),
  );
}

class _Featured extends StatelessWidget {
  const _Featured({required this.book, required this.count, required this.onTap});
  final Book book;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 235,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0C2C62), AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Color(0x333157D5), blurRadius: 25, offset: Offset(0, 13))]),
    child: Stack(children: [
      Positioned(right: -45, top: -45, child: Container(width: 180, height: 180, decoration: const BoxDecoration(color: Color(0x1AFFFFFF), shape: BoxShape.circle))),
      Positioned(right: -20, bottom: -35, child: Transform.rotate(angle: .08, child: ClipRRect(borderRadius: BorderRadius.circular(14), child: book.image.isEmpty ? Container(width: 135, height: 200, color: AppColors.sky, child: const Icon(Icons.menu_book_rounded, size: 48, color: AppColors.blue)) : CachedNetworkImage(imageUrl: book.image, width: 135, height: 200, fit: BoxFit.cover, errorWidget: (_, __, ___) => Container(width: 135, height: 200, color: AppColors.sky, child: const Icon(Icons.menu_book_rounded, color: AppColors.blue)))))),
      Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(width: MediaQuery.sizeOf(context).width * .55, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: const Color(0x2AFFFFFF), borderRadius: BorderRadius.circular(9)), child: Text('$count DOCUMENTS', style: const TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900, color: Colors.white))),
          const SizedBox(height: 13),
          const Text('Le savoir, partout avec vous.', maxLines: 2, style: TextStyle(fontSize: 25, height: 1.05, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 8),
          Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, height: 1.35, color: Color(0xFFDCE6FF))),
          const Spacer(),
          FilledButton.icon(onPressed: onTap, style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue, minimumSize: const Size(0, 42)), icon: const Icon(Icons.auto_stories_rounded, size: 18), label: const Text('Découvrir')),
        ])),
      ),
    ]),
  );
}

class _FirstOfflineWelcome extends StatelessWidget {
  const _FirstOfflineWelcome();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)), borderRadius: BorderRadius.circular(22)),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(backgroundColor: AppColors.sky, child: Icon(Icons.auto_stories_rounded, color: AppColors.blue)),
      SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Votre bibliothèque reste accessible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), SizedBox(height: 6), Text('Dès que la connexion revient, le catalogue se synchronise automatiquement. Vos documents déjà enregistrés restent lisibles sans Internet.', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted))])),
    ]),
  );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.values, required this.onExplore});
  final List<String> values;
  final VoidCallback onExplore;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 45,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ActionChip(onPressed: onExplore, avatar: const Icon(Icons.grid_view_rounded, size: 15, color: AppColors.blue), label: Text(categoryLabel(values[i]), maxLines: 1, overflow: TextOverflow.ellipsis), side: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5)), backgroundColor: Theme.of(context).colorScheme.surface),
    ),
  );
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.books, required this.state, required this.onBook});
  final String title;
  final List<Book> books;
  final AppState state;
  final ValueChanged<Book> onBook;
  @override
  Widget build(BuildContext context) => Column(children: [
    SectionTitle(title, action: 'Voir tout'),
    SizedBox(height: 304, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: books.length, separatorBuilder: (_, __) => const SizedBox(width: 12), itemBuilder: (_, i) => BookCard(book: books[i], favorite: state.favorites.contains(books[i].id), onTap: () => onBook(books[i]), onFavorite: () => state.toggleFavorite(books[i].id)))),
  ]);
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 27, 16, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFF8E8), Color(0xFFFFEFC4)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1D99E))),
    child: Row(children: [Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.psychology_alt_rounded, color: AppColors.gold)), const SizedBox(width: 14), const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Besoin d’un coup de pouce ?', style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)), SizedBox(height: 3), Text('L’assistant Fasobiblio vous guide dans vos recherches.', style: TextStyle(fontSize: 11, color: AppColors.muted))])), IconButton(onPressed: onTap, icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.gold))]),
  );
}
