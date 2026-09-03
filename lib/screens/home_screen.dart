import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../services/document_service.dart';
import '../widgets/book_card.dart';
import '../widgets/document_cover.dart';
import 'pdf_reader_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.state, required this.onExplore, required this.onBook});

  final AppState state;
  final VoidCallback onExplore;
  final ValueChanged<Book> onBook;

  Book? _continueBook() {
    final read = state.books.where((book) {
      final byId = state.readingFor(book.id);
      final byTitle = state.readingFor(book.title);
      return byId.isNotEmpty || byTitle.isNotEmpty;
    }).toList();
    if (read.isEmpty) return null;
    read.sort((a, b) {
      final aData = state.readingFor(a.id).isNotEmpty ? state.readingFor(a.id) : state.readingFor(a.title);
      final bData = state.readingFor(b.id).isNotEmpty ? state.readingFor(b.id) : state.readingFor(b.title);
      final aTime = (aData['updatedAt'] as num?)?.toInt() ?? 0;
      final bTime = (bData['updatedAt'] as num?)?.toInt() ?? 0;
      return bTime.compareTo(aTime);
    });
    return read.first;
  }

  Future<void> _resume(BuildContext context, Book book) async {
    final service = DocumentService();
    final cacheKey = '${book.id}-${book.title}';
    final path = await service.cached(cacheKey);
    if (!context.mounted) return;
    if (path == null) {
      onBook(book);
      return;
    }
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfReaderScreen(path: path, title: book.title, state: state, documentId: book.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final popular = [...state.books]..sort((a, b) => b.views.compareTo(a.views));
    final recent = [...state.books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final premium = state.books.where((book) => book.isPremium).toList();
    final categories = state.books.map((book) => book.category).where((value) => value.isNotEmpty).toSet().take(8).toList();
    final continueBook = _continueBook();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _TopIntro(count: state.books.length, onExplore: onExplore)),
      if (continueBook != null)
        SliverToBoxAdapter(child: _ContinueReading(
          book: continueBook,
          progress: state.readingProgress(continueBook.id) > 0 ? state.readingProgress(continueBook.id) : state.readingProgress(continueBook.title),
          page: state.readingFor(continueBook.id).isNotEmpty ? state.readingPage(continueBook.id) : state.readingPage(continueBook.title),
          onTap: () => _resume(context, continueBook),
        )),
      if (categories.isNotEmpty) SliverToBoxAdapter(child: _CategoryStrip(values: categories, onExplore: onExplore)),
      if (recent.isNotEmpty) SliverToBoxAdapter(child: _BookShelf(title: 'Nouveautés', subtitle: 'Fraîchement ajoutés', books: recent.take(10).toList(), state: state, onBook: onBook)),
      if (popular.isNotEmpty) SliverToBoxAdapter(child: _BookShelf(title: 'Les plus lus', subtitle: 'En ce moment sur Fasobiblio', books: popular.take(10).toList(), state: state, onBook: onBook)),
      if (premium.isNotEmpty) SliverToBoxAdapter(child: _BookShelf(title: 'Sélection Premium', subtitle: 'Des ressources choisies pour aller plus loin', books: premium.take(10).toList(), state: state, onBook: onBook, premium: true)),
      if (state.books.isEmpty) const SliverToBoxAdapter(child: _OfflineEmpty()),
      SliverToBoxAdapter(child: _DiscoverBanner(onTap: onExplore)),
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ]);
  }
}

class _TopIntro extends StatelessWidget {
  const _TopIntro({required this.count, required this.onExplore});
  final int count;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    padding: const EdgeInsets.fromLTRB(20, 19, 20, 18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0A1D3D), Color(0xFF123F8C), AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x260B3FB9), blurRadius: 24, offset: Offset(0, 12))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FASOBIBLIO', style: TextStyle(fontSize: 10, letterSpacing: 1.6, fontWeight: FontWeight.w900, color: Color(0xFF98B9FF))),
          const SizedBox(height: 7),
          Text('Qu’allez-vous lire\naujourd’hui ?', style: AppTypography.display(size: 28, weight: FontWeight.w900, color: Colors.white)),
        ])),
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0x18FFFFFF))),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$count', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
            const Text('docs', style: TextStyle(fontSize: 8.5, color: Color(0xFFC7D8FF))),
          ]),
        ),
      ]),
      const SizedBox(height: 19),
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onExplore,
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
            child: Row(children: [
              Icon(AppIcons.search, size: 20, color: AppColors.blueDeep),
              SizedBox(width: 11),
              Expanded(child: Text('Titre, auteur, matière…', style: TextStyle(fontSize: 12, color: AppColors.muted))),
              CircleAvatar(radius: 16, backgroundColor: AppColors.sky, child: Icon(AppIcons.arrowRight, size: 16, color: AppColors.blueDeep)),
            ]),
          ),
        ),
      ),
    ]),
  );
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading({required this.book, required this.progress, required this.page, required this.onTap});
  final Book book;
  final double progress;
  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 15, 18, 4),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Continuer la lecture', style: Theme.of(context).textTheme.titleLarge)),
        Text('${(progress * 100).round()}%', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.blue)),
      ]),
      const SizedBox(height: 11),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), border: Border.all(color: AppColors.blue.withValues(alpha: .10))),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(14), child: DocumentCover(imageUrl: book.image, width: 72, height: 98)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 15.5, weight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                const SizedBox(height: 12),
                ClipRRect(borderRadius: BorderRadius.circular(99), child: LinearProgressIndicator(value: progress, minHeight: 5, backgroundColor: AppColors.sky, color: AppColors.blue)),
                const SizedBox(height: 6),
                Text('Reprendre à la page $page', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blueDeep)),
              ])),
              const SizedBox(width: 8),
              const CircleAvatar(radius: 22, backgroundColor: AppColors.blue, child: Icon(Icons.play_arrow_rounded, color: Colors.white)),
            ]),
          ),
        ),
      ),
    ]),
  );
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.values, required this.onExplore});
  final List<String> values;
  final VoidCallback onExplore;

  static const swatches = [
    Color(0xFFE8F1FF), Color(0xFFFFF0E6), Color(0xFFE7F8F0), Color(0xFFF3EBFF),
    Color(0xFFFFF6D9), Color(0xFFFFE9F0), Color(0xFFE8F7FA), Color(0xFFF0F1F4),
  ];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [
          Expanded(child: Text('Explorer par rayon', style: Theme.of(context).textTheme.titleLarge)),
          TextButton(onPressed: onExplore, child: const Text('Tout voir')),
        ]),
      ),
      SizedBox(
        height: 74,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 9),
          itemBuilder: (_, index) => InkWell(
            onTap: onExplore,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 112,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: swatches[index % swatches.length], borderRadius: BorderRadius.circular(18)),
              child: Row(children: [
                Container(width: 31, height: 31, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .85), borderRadius: BorderRadius.circular(10)), child: const Icon(AppIcons.bookOpen, size: 16, color: AppColors.blueDeep)),
                const SizedBox(width: 8),
                Expanded(child: Text(categoryLabel(values[index]), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.ink))),
              ]),
            ),
          ),
        ),
      ),
    ]),
  );
}

class _BookShelf extends StatelessWidget {
  const _BookShelf({required this.title, required this.subtitle, required this.books, required this.state, required this.onBook, this.premium = false});
  final String title;
  final String subtitle;
  final List<Book> books;
  final AppState state;
  final ValueChanged<Book> onBook;
  final bool premium;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
          ])),
          if (premium) const Icon(AppIcons.premium, size: 19, color: AppColors.gold),
        ]),
      ),
      const SizedBox(height: 11),
      SizedBox(
        height: 300,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: books.length,
          separatorBuilder: (_, __) => const SizedBox(width: 11),
          itemBuilder: (_, index) => BookCard(
            book: books[index],
            favorite: state.favorites.contains(books[index].id),
            onTap: () => onBook(books[index]),
            onFavorite: () => state.toggleFavorite(books[index].id),
            width: 154,
          ),
        ),
      ),
    ]),
  );
}

class _DiscoverBanner extends StatelessWidget {
  const _DiscoverBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(18, 25, 18, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: const Color(0xFFFFF2E8), borderRadius: BorderRadius.circular(23)),
    child: Row(children: [
      Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Icon(AppIcons.sparkles, color: Color(0xFFE86B2A))),
      const SizedBox(width: 13),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Une idée de lecture ?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.ink)),
        SizedBox(height: 4),
        Text('Explorez le catalogue ou laissez l’assistant vous guider.', style: TextStyle(fontSize: 10.5, height: 1.4, color: AppColors.muted)),
      ])),
      IconButton(onPressed: onTap, style: IconButton.styleFrom(backgroundColor: Colors.white), icon: const Icon(AppIcons.arrowRight, color: Color(0xFFE86B2A))),
    ]),
  );
}

class _OfflineEmpty extends StatelessWidget {
  const _OfflineEmpty();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(18, 22, 18, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
    child: const Row(children: [
      CircleAvatar(backgroundColor: AppColors.sky, child: Icon(AppIcons.bookOpen, color: AppColors.blue)),
      SizedBox(width: 12),
      Expanded(child: Text('Le catalogue apparaîtra après la première synchronisation. Les documents déjà enregistrés restent disponibles hors connexion.', style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted))),
    ]),
  );
}
