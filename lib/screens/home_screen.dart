import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/document_cover.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.state,
    required this.onExplore,
    required this.onBook,
    required this.onNotifications,
  });

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
      final haystack = [
        book.title,
        book.author,
        book.description,
        book.category,
        book.level,
        book.year,
        book.language,
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).take(30).toList();
  }

  @override
  Widget build(BuildContext context) {
    final popular = [...widget.state.books]..sort((a, b) => b.views.compareTo(a.views));
    final recent = [...widget.state.books]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final categories = widget.state.books.map((b) => b.category).where((v) => v.isNotEmpty).toSet().take(7).toList();
    final lastOpened = widget.state.lastOpenedBook;
    final results = searchResults;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _SimpleHeader(
            unread: widget.state.unreadNotifications,
            onNotifications: widget.onNotifications,
            onExplore: widget.onExplore,
            onQueryChanged: (value) => setState(() => query = value),
          ),
        ),
        if (query.trim().isNotEmpty) ...[
          SliverToBoxAdapter(child: _SectionHeader(title: 'Résultats', action: '${results.length} trouvé${results.length > 1 ? 's' : ''}')),
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
          if (categories.isNotEmpty) SliverToBoxAdapter(child: _Categories(values: categories, onExplore: widget.onExplore)),
          if (recent.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Nouveautés', books: recent.take(10).toList(), state: widget.state, onBook: widget.onBook)),
          if (popular.isNotEmpty) SliverToBoxAdapter(child: _Shelf(title: 'Les plus consultés', books: popular.take(10).toList(), state: widget.state, onBook: widget.onBook)),
          if (widget.state.books.isEmpty) const SliverToBoxAdapter(child: _Offline()),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _SimpleHeader extends StatelessWidget {
  const _SimpleHeader({
    required this.unread,
    required this.onNotifications,
    required this.onExplore,
    required this.onQueryChanged,
  });

  final int unread;
  final VoidCallback onNotifications;
  final VoidCallback onExplore;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'FASOBIBLIO',
                    style: AppTypography.display(
                      size: 20,
                      weight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ).copyWith(letterSpacing: .3),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: onNotifications,
                      tooltip: 'Notifications',
                      icon: const Icon(AppIcons.bell, size: 22),
                    ),
                    if (unread > 0)
                      Positioned(
                        right: 5,
                        top: 4,
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(color: Color(0xFFE5484D), shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              onChanged: onQueryChanged,
              textInputAction: TextInputAction.search,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                hintText: 'Titre, auteur, matière, niveau…',
                hintStyle: const TextStyle(fontSize: 11.5, color: AppColors.muted, fontWeight: FontWeight.w500),
                prefixIcon: const Icon(AppIcons.search, size: 19),
                suffixIcon: IconButton(
                  tooltip: 'Recherche avancée',
                  onPressed: onExplore,
                  icon: const Icon(AppIcons.filters, size: 18),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .7)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: AppColors.blue, width: 1.2),
                ),
              ),
            ),
          ],
        ),
      );
}

class _DailyDocument extends StatelessWidget {
  const _DailyDocument({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DOCUMENT DU JOUR',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: .45, color: AppColors.ink),
            ),
            const SizedBox(height: 9),
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                child: Ink(
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE8F2FF), Color(0xFFF5F8FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: CustomPaint(painter: _BookMotifPainter())),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: DocumentCover(imageUrl: book.image, width: 82, height: 118),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    book.title,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bookTitle(size: 14.5, weight: FontWeight.w900, color: AppColors.ink),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    book.author.isEmpty ? 'Auteur non renseigné' : book.author,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 12),
                                  const Row(
                                    children: [
                                      Text('Voir le document', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.blueDeep)),
                                      SizedBox(width: 6),
                                      Icon(AppIcons.arrowRight, size: 16, color: AppColors.blueDeep),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _BookMotifPainter extends CustomPainter {
  const _BookMotifPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.blue.withValues(alpha: .055)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (double x = size.width * .55; x < size.width + 30; x += 42) {
      for (double y = -10; y < size.height + 20; y += 42) {
        final rect = Rect.fromLTWH(x, y, 24, 18);
        canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), paint);
        canvas.drawLine(Offset(x + 12, y), Offset(x + 12, y + 18), paint);
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('CONTINUER LA LECTURE', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, letterSpacing: .4)),
            const SizedBox(height: 9),
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .6)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(9), child: DocumentCover(imageUrl: book.image, width: 58, height: 80)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 13, weight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
                            const SizedBox(height: 8),
                            const Text('Reprendre', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: AppColors.blue)),
                          ],
                        ),
                      ),
                      const Icon(AppIcons.chevronRight, size: 18, color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Categories extends StatelessWidget {
  const _Categories({required this.values, required this.onExplore});
  final List<String> values;
  final VoidCallback onExplore;
  static const colors = [Color(0xFFEAF1FF), Color(0xFFFFF0E7), Color(0xFFEAF8F1), Color(0xFFF3ECFF), Color(0xFFFFF5D9), Color(0xFFFFEAF0)];

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Catégories', onTap: onExplore),
            SizedBox(
              height: 64,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (_, i) => Material(
                  color: colors[i % colors.length],
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: onExplore,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 92, maxWidth: 128),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(AppIcons.bookOpen, size: 16, color: AppColors.blueDeep),
                          const SizedBox(height: 5),
                          Text(categoryLabel(values[i]), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.ink)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onTap, this.action});
  final String title;
  final VoidCallback? onTap;
  final String? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900))),
            if (action != null)
              Text(action!, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.muted))
            else if (onTap != null)
              TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
                child: const Text('Voir tout', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
          ],
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
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: title),
            SizedBox(
              height: 260,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                separatorBuilder: (_, __) => const SizedBox(width: 13),
                itemBuilder: (_, i) => BookCard(
                  book: books[i],
                  favorite: state.favorites.contains(books[i].id),
                  onTap: () => onBook(books[i]),
                  onFavorite: () => state.toggleFavorite(books[i].id),
                  width: 132,
                ),
              ),
            ),
          ],
        ),
      );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
        child: const Column(
          children: [
            Icon(AppIcons.search, size: 24, color: AppColors.muted),
            SizedBox(height: 8),
            Text('Aucun document trouvé', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900)),
            SizedBox(height: 4),
            Text('Essayez un titre, un auteur, une matière ou un niveau.', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: AppColors.muted)),
          ],
        ),
      );
}

class _Offline extends StatelessWidget {
  const _Offline();
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(18, 22, 18, 0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
        child: const Text(
          'Le catalogue apparaîtra après la première synchronisation. Vos documents enregistrés restent disponibles hors connexion.',
          style: TextStyle(fontSize: 10, height: 1.45, color: AppColors.muted, fontWeight: FontWeight.w600),
        ),
      );
}
