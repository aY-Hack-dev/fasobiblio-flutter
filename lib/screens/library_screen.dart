import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/section.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.state, required this.onBook});
  final AppState state;
  final ValueChanged<Book> onBook;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int section = 0;

  @override
  Widget build(BuildContext context) {
    final ids = section == 0 ? widget.state.favorites : section == 1 ? widget.state.later : widget.state.purchased;
    final books = widget.state.books.where((b) => ids.contains(b.id)).toList();
    final total = widget.state.favorites.length + widget.state.later.length + widget.state.purchased.length;

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _LibraryHeader(total: total)),
      SliverToBoxAdapter(child: _SegmentedLibrary(
        section: section,
        favorites: widget.state.favorites.length,
        later: widget.state.later.length,
        purchased: widget.state.purchased.length,
        onChanged: (value) => setState(() => section = value),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Row(children: [
          Expanded(child: Text(section == 0 ? 'Mes favoris' : section == 1 ? 'À lire plus tard' : 'Mes achats', style: Theme.of(context).textTheme.titleLarge)),
          Text('${books.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.blueDeep)),
        ]),
      )),
      SliverToBoxAdapter(
        child: books.isEmpty
            ? EmptyState(
                title: section == 0 ? 'Aucun favori' : section == 1 ? 'Votre liste est vide' : 'Aucun achat',
                message: section == 0
                    ? 'Touchez le cœur d’un ouvrage pour le retrouver ici.'
                    : section == 1
                        ? 'Enregistrez des documents pour les lire plus tard.'
                        : 'Vos documents Premium achetés apparaîtront ici.',
                icon: section == 0 ? AppIcons.heart : section == 1 ? AppIcons.bookmark : AppIcons.shoppingBag,
              )
            : BookGrid(
                books: books,
                favorites: widget.state.favorites,
                onBook: widget.onBook,
                onFavorite: (book) => widget.state.toggleFavorite(book.id),
              ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: 34)),
    ]);
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({required this.total});
  final int total;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
    height: 158,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF071A38), Color(0xFF0B3FB9), Color(0xFF1764E8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x2310379D), blurRadius: 22, offset: Offset(0, 10))],
    ),
    child: Stack(children: [
      const Positioned.fill(child: CustomPaint(painter: _LibraryPatternPainter())),
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('MA BIBLIOTHÈQUE', style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w900, color: Color(0xFFBFD2FF))),
            const SizedBox(height: 8),
            Text('Tout ce que vous\navez gardé.', style: AppTypography.display(size: 24, weight: FontWeight.w900, color: Colors.white)),
            const SizedBox(height: 8),
            Text('$total document(s) dans votre espace', style: const TextStyle(fontSize: 10.5, color: Color(0xFFD9E5FF))),
          ])),
          Container(width: 62, height: 62, decoration: BoxDecoration(color: const Color(0x18FFFFFF), borderRadius: BorderRadius.circular(20)), child: const Icon(AppIcons.library, color: Colors.white, size: 28)),
        ]),
      ),
    ]),
  );
}

class _LibraryPatternPainter extends CustomPainter {
  const _LibraryPatternPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: .05)..style = PaintingStyle.stroke..strokeWidth = 1.3;
    for (double y = -18; y < size.height + 20; y += 36) {
      for (double x = -18; x < size.width + 20; x += 36) {
        canvas.drawRect(Rect.fromCenter(center: Offset(x + 12, y + 12), width: 15, height: 15), paint);
        canvas.drawCircle(Offset(x + 12, y + 12), 3, paint);
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SegmentedLibrary extends StatelessWidget {
  const _SegmentedLibrary({required this.section, required this.favorites, required this.later, required this.purchased, required this.onChanged});
  final int section;
  final int favorites;
  final int later;
  final int purchased;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .45))),
      child: Row(children: [
        _LibraryTab(label: 'Favoris', count: favorites, selected: section == 0, onTap: () => onChanged(0)),
        _LibraryTab(label: 'À lire', count: later, selected: section == 1, onTap: () => onChanged(1)),
        _LibraryTab(label: 'Achats', count: purchased, selected: section == 2, onTap: () => onChanged(2)),
      ]),
    ),
  );
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({required this.label, required this.count, required this.selected, required this.onTap});
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(color: selected ? AppColors.blueDeep : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Text('$label  $count', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: selected ? Colors.white : AppColors.muted)),
      ),
    ),
  );
}
