import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/document_cover.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.state, required this.onExplore, required this.onBook, required this.onNotifications});
  final AppState state;
  final VoidCallback onExplore;
  final ValueChanged<Book> onBook;
  final VoidCallback onNotifications;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String query = '';

  Book? get dailyBook {
    if (widget.state.books.isEmpty) return null;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return widget.state.books[day % widget.state.books.length];
  }

  List<Book> get searchResults {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return widget.state.books.where((book) {
      final haystack = [book.title, book.author, book.description, book.category, book.level, book.year, book.language].join(' ').toLowerCase();
      return haystack.contains(q);
    }).take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final recent = [...widget.state.books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final popular = [...widget.state.books]..sort((a, b) => b.views.compareTo(a.views));
    final categories = <String, int>{};
    for (final book in widget.state.books) {
      if (book.category.isNotEmpty) categories[book.category] = (categories[book.category] ?? 0) + 1;
    }
    final categoryEntries = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final results = searchResults;
    final lastOpened = widget.state.lastOpenedBook;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _SearchBox(onChanged: (v) => setState(() => query = v), onAdvanced: widget.onExplore)),
        if (query.trim().isNotEmpty) ...[
          SliverToBoxAdapter(child: _SectionHeader(title: 'Résultats', trailing: '${results.length}')),
          SliverToBoxAdapter(
            child: results.isEmpty
                ? const _EmptySearch()
                : BookGrid(
                    books: results,
                    favorites: widget.state.favorites,
                    onBook: widget.onBook,
                    onFavorite: (book) => widget.state.toggleFavorite(book.id),
                  ),
          ),
        ] else ...[
          if (dailyBook != null) SliverToBoxAdapter(child: _DailyDocument(book: dailyBook!, onTap: () => widget.onBook(dailyBook!))),
          if (lastOpened != null) SliverToBoxAdapter(child: _ContinueReading(book: lastOpened, onTap: () => widget.onBook(lastOpened))),
          if (categoryEntries.isNotEmpty) SliverToBoxAdapter(child: _Categories(entries: categoryEntries.take(6).toList(), onExplore: widget.onExplore)),
          if (recent.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Nouveautés', books: recent.take(10).toList(), state: widget.state, onBook: widget.onBook)),
          if (popular.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Les plus consultés', books: popular.take(10).toList(), state: widget.state, onBook: widget.onBook)),
          if (widget.state.books.isEmpty) const SliverToBoxAdapter(child: _Offline()),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onChanged, required this.onAdvanced});
  final ValueChanged<String> onChanged;
  final VoidCallback onAdvanced;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        child: TextField(
          onChanged: onChanged,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Titre, auteur, matière, niveau…',
            hintStyle: const TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w500),
            prefixIcon: const Icon(AppIcons.search, size: 19),
            suffixIcon: IconButton(onPressed: onAdvanced, tooltip: 'Recherche avancée', icon: const Icon(AppIcons.filters, size: 18)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 11),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .55))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.blue, width: 1.2)),
          ),
        ),
      );
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: .72),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap, this.trailing});
  final String title;
  final VoidCallback? onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
        child: Row(children: [
          Expanded(
            child: Text(
              title,
              style: AppTypography.display(size: 14, weight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          if (trailing != null) Text(trailing!, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4), minimumSize: const Size(0, 28)),
              child: const Text('Voir tout', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
            ),
        ]),
      );
}

class _DailyDocument extends StatelessWidget {
  const _DailyDocument({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SectionBlock(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHeader(title: 'Document du jour'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Ink(
                  height: 172,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFFEAF2FF), Color(0xFFF7F9FF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(children: [
                    const Positioned.fill(child: CustomPaint(painter: _BookMotifPainter())),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(children: [
                        ClipRRect(borderRadius: BorderRadius.circular(11), child: DocumentCover(imageUrl: book.image, width: 98, height: 142)),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text(book.title, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 14, weight: FontWeight.w900, color: AppColors.ink)),
                            const SizedBox(height: 5),
                            Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.muted, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 13),
                            const Row(children: [
                              Text('Voir le document', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.blueDeep)),
                              SizedBox(width: 5),
                              Icon(AppIcons.arrowRight, size: 15, color: AppColors.blueDeep),
                            ]),
                          ]),
                        ),
                      ]),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}

class _BookMotifPainter extends CustomPainter {
  const _BookMotifPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.blue.withValues(alpha: .05)..style = PaintingStyle.stroke..strokeWidth = 1.1;
    for (double x = size.width * .55; x < size.width + 24; x += 38) {
      for (double y = -8; y < size.height + 20; y += 38) {
        final rect = Rect.fromLTWH(x, y, 22, 17);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
        canvas.drawLine(Offset(x + 11, y), Offset(x + 11, y + 17), paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ContinueReading extends StatelessWidget {
  const _ContinueReading({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _SectionBlock(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHeader(title: 'Continuer la lecture'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(children: [
                    ClipRRect(borderRadius: BorderRadius.circular(9), child: DocumentCover(imageUrl: book.image, width: 66, height: 92)),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 12.5, weight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                      const SizedBox(height: 9),
                      const Text('Reprendre', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.blue)),
                    ])),
                    const Icon(AppIcons.chevronRight, size: 18, color: AppColors.muted),
                  ]),
                ),
              ),
            ),
          ),
        ]),
      );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.entries, required this.onExplore});
  final List<MapEntry<String, int>> entries;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => _SectionBlock(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionHeader(title: 'Catégories', onTap: onExplore),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entries.map((entry) => InkWell(
                onTap: onExplore,
                borderRadius: BorderRadius.circular(99),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(AppIcons.bookOpen, size: 14, color: AppColors.blueDeep),
                    const SizedBox(width: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 130),
                      child: Text(categoryLabel(entry.key), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 5),
                    Text('${entry.value}', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: AppColors.muted)),
                  ]),
                ),
              )).toList(),
            ),
          ),
        ]),
      );
}

class _Shelf extends StatelessWidget {
  const _Shelf({required this.title, required this.books, required this.state, required this.onBook});
  final String title;
  final List<Book> books;
  final AppState state;
  final ValueChanged<Book> onBook;

  @override
  Widget build(BuildContext context) => _SectionBlock(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionHeader(title: title),
          SizedBox(
            height: 300,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: books.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (_, i) => BookCard(
                book: books[i],
                favorite: state.favorites.contains(books[i].id),
                onTap: () => onBook(books[i]),
                onFavorite: () => state.toggleFavorite(books[i].id),
                width: 184,
              ),
            ),
          ),
        ]),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.fromLTRB(18, 24, 18, 36),
        child: Center(child: Text('Aucun document trouvé.', style: TextStyle(fontSize: 11, color: AppColors.muted, fontWeight: FontWeight.w700))),
      );
}

class _Offline extends StatelessWidget {
  const _Offline();
  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text('Le catalogue apparaîtra dès que la connexion sera disponible.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.muted))),
      );
}
