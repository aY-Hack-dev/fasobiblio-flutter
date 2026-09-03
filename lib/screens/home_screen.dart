import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/document_cover.dart';
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
      SliverToBoxAdapter(child: _WelcomeBlock(count: state.books.length, onExplore: onExplore)),
      if (featured != null) SliverToBoxAdapter(child: _Featured(book: featured, onTap: () => onBook(featured))),
      if (state.books.isEmpty) const SliverToBoxAdapter(child: _FirstOfflineWelcome()),
      if (categories.isNotEmpty) ...[
        const SliverToBoxAdapter(child: SectionTitle('Explorer les rayons')),
        SliverToBoxAdapter(child: _Categories(values: categories, onExplore: onExplore)),
      ],
      if (popular.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Populaires maintenant', subtitle: 'Les documents les plus consultés', books: popular.take(10).toList(), state: state, onBook: onBook)),
      if (recent.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Nouveautés', subtitle: 'Les dernières ressources ajoutées', books: recent.take(10).toList(), state: state, onBook: onBook)),
      if (premium.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Sélection Premium', subtitle: 'Des contenus à forte valeur ajoutée', books: premium.take(10).toList(), state: state, onBook: onBook, premium: true)),
      SliverToBoxAdapter(child: _StudyCard(onTap: onExplore)),
      const SliverToBoxAdapter(child: SizedBox(height: 34)),
    ]);
  }
}

class _WelcomeBlock extends StatelessWidget {
  const _WelcomeBlock({required this.count, required this.onExplore});
  final int count;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('BIBLIOTHÈQUE NUMÉRIQUE', style: TextStyle(fontSize: 9.5, letterSpacing: 1.2, fontWeight: FontWeight.w900, color: AppColors.blue)),
          const SizedBox(height: 5),
          Text('Le savoir qui vous accompagne partout.', style: Theme.of(context).textTheme.headlineLarge),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(13)),
          child: Text('$count docs', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.blue)),
        ),
      ]),
      const SizedBox(height: 8),
      const Text('Cours, livres, mémoires et ressources pédagogiques réunis dans une expérience simple et moderne.', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
      const SizedBox(height: 16),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 3,
        shadowColor: const Color(0x141860F0),
        child: InkWell(
          onTap: onExplore,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(border: Border.all(color: AppColors.blue.withValues(alpha: .12)), borderRadius: BorderRadius.circular(18)),
            child: const Row(children: [
              CircleAvatar(radius: 18, backgroundColor: AppColors.sky, child: Icon(AppIcons.search, color: AppColors.blue, size: 18)),
              SizedBox(width: 12),
              Expanded(child: Text('Rechercher un livre, un cours, une matière…', style: TextStyle(fontSize: 12, color: AppColors.muted))),
              Icon(AppIcons.arrowRight, size: 19, color: AppColors.blue),
            ]),
          ),
        ),
      ),
    ]),
  );
}

class _Featured extends StatelessWidget {
  const _Featured({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    height: 240,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF07142B), AppColors.blueDeep, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x331860F0), blurRadius: 28, offset: Offset(0, 15))],
    ),
    child: Stack(children: [
      Positioned(right: -60, top: -50, child: Container(width: 210, height: 210, decoration: const BoxDecoration(color: Color(0x16FFFFFF), shape: BoxShape.circle))),
      Positioned(right: 18, bottom: -16, child: Transform.rotate(angle: .055, child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 20, offset: Offset(0, 10))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: DocumentCover(imageUrl: book.image, width: 132, height: 190)),
      ))),
      Padding(
        padding: const EdgeInsets.all(22),
        child: SizedBox(width: MediaQuery.sizeOf(context).width * .54, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0x18FFFFFF))),
            child: const Text('À DÉCOUVRIR', style: TextStyle(fontSize: 8.5, letterSpacing: .9, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 13),
          Text(book.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 22, weight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 7),
          Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, color: Color(0xFFDCE6FF))),
          const Spacer(),
          FilledButton.icon(
            onPressed: onTap,
            style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.blue, minimumSize: const Size(0, 42)),
            icon: const Icon(AppIcons.bookOpen, size: 18),
            label: const Text('Voir le document'),
          ),
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
      CircleAvatar(backgroundColor: AppColors.sky, child: Icon(AppIcons.bookOpen, color: AppColors.blue)),
      SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Votre bibliothèque reste accessible', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text('Dès que la connexion revient, le catalogue se synchronise automatiquement. Vos documents déjà enregistrés restent lisibles sans Internet.', style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
      ])),
    ]),
  );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.values, required this.onExplore});
  final List<String> values;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      scrollDirection: Axis.horizontal,
      itemCount: values.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => ActionChip(
        onPressed: onExplore,
        avatar: const Icon(AppIcons.grid, size: 15, color: AppColors.blue),
        label: Text(categoryLabel(values[i]), maxLines: 1, overflow: TextOverflow.ellipsis),
        side: BorderSide(color: AppColors.blue.withValues(alpha: .12)),
        backgroundColor: Colors.white,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
      ),
    ),
  );
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.subtitle, required this.books, required this.state, required this.onBook, this.premium = false});
  final String title;
  final String subtitle;
  final List<Book> books;
  final AppState state;
  final ValueChanged<Book> onBook;
  final bool premium;

  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 10),
      child: Row(children: [
        Container(width: 4, height: 36, decoration: BoxDecoration(color: premium ? AppColors.gold : AppColors.blue, borderRadius: BorderRadius.circular(99))),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
        ])),
        const Text('Voir tout', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.blue)),
      ]),
    ),
    SizedBox(
      height: 318,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: books.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => BookCard(
          book: books[i],
          favorite: state.favorites.contains(books[i].id),
          onTap: () => onBook(books[i]),
          onFavorite: () => state.toggleFavorite(books[i].id),
        ),
      ),
    ),
  ]);
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.blueDeep, AppColors.blue]),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [BoxShadow(color: Color(0x261860F0), blurRadius: 20, offset: Offset(0, 10))],
    ),
    child: Row(children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(AppIcons.brain, color: AppColors.blue)),
      const SizedBox(width: 14),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Besoin d’un coup de pouce ?', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
        SizedBox(height: 4),
        Text('L’assistant Fasobiblio vous guide dans vos recherches.', style: TextStyle(fontSize: 11, height: 1.4, color: Color(0xFFDDE8FF))),
      ])),
      IconButton(onPressed: onTap, style: IconButton.styleFrom(backgroundColor: const Color(0x18FFFFFF)), icon: const Icon(AppIcons.arrowRight, color: Colors.white)),
    ]),
  );
}
