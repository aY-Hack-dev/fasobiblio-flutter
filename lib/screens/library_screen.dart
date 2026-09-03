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
      SliverToBoxAdapter(child: _LibraryHero(
        total: total,
        favorites: widget.state.favorites.length,
        later: widget.state.later.length,
        purchased: widget.state.purchased.length,
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .55)),
            boxShadow: const [BoxShadow(color: Color(0x110F172A), blurRadius: 14, offset: Offset(0, 6))],
          ),
          child: Row(children: [
            _LibraryTab(label: 'Favoris', icon: AppIcons.heart, count: widget.state.favorites.length, selected: section == 0, onTap: () => setState(() => section = 0)),
            _LibraryTab(label: 'À lire', icon: AppIcons.bookmark, count: widget.state.later.length, selected: section == 1, onTap: () => setState(() => section = 1)),
            _LibraryTab(label: 'Achats', icon: AppIcons.shoppingBag, count: widget.state.purchased.length, selected: section == 2, onTap: () => setState(() => section = 2)),
          ]),
        ),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
        child: Row(children: [
          Expanded(child: Text(
            section == 0 ? 'Vos favoris' : section == 1 ? 'À lire plus tard' : 'Vos achats Premium',
            style: Theme.of(context).textTheme.titleLarge,
          )),
          Text('${books.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.blue)),
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

class _LibraryHero extends StatelessWidget {
  const _LibraryHero({required this.total, required this.favorites, required this.later, required this.purchased});
  final int total;
  final int favorites;
  final int later;
  final int purchased;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.ink, AppColors.blueDeep], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x2A0B3FB9), blurRadius: 24, offset: Offset(0, 12))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Votre espace de lecture.', style: AppTypography.display(size: 23, weight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 7),
          const Text('Tout ce que vous aimez, sauvegardez ou achetez, au même endroit.', style: TextStyle(fontSize: 12, height: 1.45, color: Color(0xFFD8E3FF))),
        ])),
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(17)),
          child: const Icon(AppIcons.library, color: Colors.white, size: 25),
        ),
      ]),
      const SizedBox(height: 18),
      Row(children: [
        _Metric(value: '$total', label: 'Enregistrés'),
        const SizedBox(width: 9),
        _Metric(value: '$favorites', label: 'Favoris'),
        const SizedBox(width: 9),
        _Metric(value: '$purchased', label: 'Achats'),
      ]),
    ]),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
      decoration: BoxDecoration(color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0x18FFFFFF))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: AppTypography.display(size: 18, weight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9.5, color: Color(0xFFD8E3FF))),
      ]),
    ),
  );
}

class _LibraryTab extends StatelessWidget {
  const _LibraryTab({required this.label, required this.icon, required this.count, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          Icon(icon, size: 18, color: selected ? Colors.white : AppColors.muted),
          const SizedBox(height: 4),
          Text('$label ($count)', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.muted)),
        ]),
      ),
    ),
  );
}
