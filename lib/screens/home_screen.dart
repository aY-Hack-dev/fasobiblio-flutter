import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/document_cover.dart';

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
    final categories = state.books.map((book) => book.category).where((value) => value.isNotEmpty).toSet().take(8).toList();
    final featured = popular.isEmpty ? null : popular.first;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _LandingHeader(count: state.books.length, onExplore: onExplore)),
      if (categories.isNotEmpty) SliverToBoxAdapter(child: _CategoryTabs(values: categories, onTap: onExplore)),
      if (featured != null) SliverToBoxAdapter(child: _FeaturedRow(book: featured, onTap: () => onBook(featured))),
      if (recent.isNotEmpty) SliverToBoxAdapter(child: _CoverShelf(title: 'Continuer à découvrir', books: recent.take(10).toList(), state: state, onBook: onBook)),
      if (popular.isNotEmpty) SliverToBoxAdapter(child: _CoverShelf(title: 'Les plus populaires', books: popular.take(10).toList(), state: state, onBook: onBook)),
      if (premium.isNotEmpty) SliverToBoxAdapter(child: _CoverShelf(title: 'Sélection Premium', books: premium.take(10).toList(), state: state, onBook: onBook, premium: true)),
      if (state.books.isEmpty) const SliverToBoxAdapter(child: _OfflineState()),
      SliverToBoxAdapter(child: _AssistantBanner(onTap: onExplore)),
      const SliverToBoxAdapter(child: SizedBox(height: 34)),
    ]);
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader({required this.count, required this.onExplore});
  final int count;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    height: 230,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF071A38), Color(0xFF0B3FB9), Color(0xFF1764E8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x2610379D), blurRadius: 24, offset: Offset(0, 12))],
    ),
    child: Stack(children: [
      const Positioned.fill(child: CustomPaint(painter: _MotifPainter())),
      Positioned(right: 18, top: 16, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(99)),
        child: Text('$count documents', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white)),
      )),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 26, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('FASOBIBLIO', style: TextStyle(fontSize: 9, letterSpacing: 1.8, fontWeight: FontWeight.w900, color: Color(0xFFBFD2FF))),
          const SizedBox(height: 10),
          Text('Lis. Apprends.\nGrandis.', style: AppTypography.display(size: 29, weight: FontWeight.w900, color: Colors.white)),
          const Spacer(),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: onExplore,
              borderRadius: BorderRadius.circular(17),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                child: Row(children: [
                  Icon(AppIcons.search, size: 20, color: AppColors.blueDeep),
                  SizedBox(width: 10),
                  Expanded(child: Text('Rechercher un livre, un cours…', style: TextStyle(fontSize: 11.5, color: AppColors.muted))),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: Color(0xFFEAF1FF), shape: BoxShape.circle),
                    child: Icon(AppIcons.arrowRight, size: 17, color: AppColors.blueDeep),
                  ),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ]),
  );
}

class _MotifPainter extends CustomPainter {
  const _MotifPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .055)..style = PaintingStyle.stroke..strokeWidth = 1.4;
    const step = 38.0;
    for (double y = -20; y < size.height + 20; y += step) {
      for (double x = -20; x < size.width + 20; x += step) {
        final path = Path()..moveTo(x, y + 10)..lineTo(x + 10, y)..lineTo(x + 20, y + 10)..lineTo(x + 10, y + 20)..close();
        canvas.drawPath(path, paint);
      }
    }
    final glow = Paint()..color = const Color(0x18FFFFFF);
    canvas.drawCircle(Offset(size.width * .92, size.height * .17), 74, glow);
    canvas.drawCircle(Offset(size.width * .78, size.height * .12), 34, glow);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.values, required this.onTap});
  final List<String> values;
  final VoidCallback onTap;
  static const colors = [Color(0xFFEAF1FF), Color(0xFFFFF0E7), Color(0xFFEAF8F1), Color(0xFFF3ECFF), Color(0xFFFFF5D9), Color(0xFFFFEAF0)];

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 17),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [Expanded(child: Text('Catégories', style: Theme.of(context).textTheme.titleLarge)), TextButton(onPressed: onTap, child: const Text('Voir tout'))]),
      ),
      SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          scrollDirection: Axis.horizontal,
          itemCount: values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (_, index) => ActionChip(
            onPressed: onTap,
            backgroundColor: colors[index % colors.length],
            side: BorderSide.none,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            avatar: const Icon(AppIcons.bookOpen, size: 14, color: AppColors.blueDeep),
            label: Text(categoryLabel(values[index]), style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.ink)),
          ),
        ),
      ),
    ]),
  );
}

class _FeaturedRow extends StatelessWidget {
  const _FeaturedRow({required this.book, required this.onTap});
  final Book book;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lecture du moment', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 11),
      Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(13), child: DocumentCover(imageUrl: book.image, width: 76, height: 108)),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 15, weight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10.5, color: AppColors.muted)),
                const SizedBox(height: 10),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: const Color(0xFFEAF1FF), borderRadius: BorderRadius.circular(9)), child: const Text('Voir le document', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.blueDeep))),
                  const Spacer(),
                  Icon(AppIcons.arrowRight, size: 19, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .55)),
                ]),
              ])),
            ]),
          ),
        ),
      ),
    ]),
  );
}

class _CoverShelf extends StatelessWidget {
  const _CoverShelf({required this.title, required this.books, required this.state, required this.onBook, this.premium = false});
  final String title;
  final List<Book> books;
  final AppState state;
  final ValueChanged<Book> onBook;
  final bool premium;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          if (premium) const Icon(AppIcons.premium, color: AppColors.gold, size: 19),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 286,
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
            width: 142,
          ),
        ),
      ),
    ]),
  );
}

class _AssistantBanner extends StatelessWidget {
  const _AssistantBanner({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(18, 26, 18, 0),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFF0E7), borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(AppIcons.brain, color: Color(0xFFE56B2F))),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Besoin d’aide pour choisir ?', style: TextStyle(fontWeight: FontWeight.w900)), SizedBox(height: 3), Text('L’assistant Fasobiblio peut vous guider.', style: TextStyle(fontSize: 10.5, color: AppColors.muted))])),
      IconButton(onPressed: onTap, icon: const Icon(AppIcons.arrowRight, color: Color(0xFFE56B2F))),
    ]),
  );
}

class _OfflineState extends StatelessWidget {
  const _OfflineState();
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(18, 22, 18, 0),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18)),
    child: const Text('Le catalogue apparaîtra après la première synchronisation. Vos documents déjà enregistrés restent disponibles hors connexion.', style: TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted)),
  );
}
