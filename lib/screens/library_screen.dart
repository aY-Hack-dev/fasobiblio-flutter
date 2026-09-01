import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/section.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.state, required this.onBook});
  final AppState state; final ValueChanged<Book> onBook;
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> {
  int section = 0;
  @override Widget build(BuildContext context) {
    final ids = section == 0 ? widget.state.favorites : section == 1 ? widget.state.later : widget.state.purchased;
    final books = widget.state.books.where((b) => ids.contains(b.id)).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ma bibliothèque', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 5), const Text('Retrouvez vos lectures personnelles et vos achats.', style: TextStyle(color: AppColors.muted)), const SizedBox(height: 18), Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)), borderRadius: BorderRadius.circular(15)), child: Row(children: [_LibraryTab(label: 'Favoris', count: widget.state.favorites.length, selected: section == 0, onTap: () => setState(() => section = 0)), _LibraryTab(label: 'À lire', count: widget.state.later.length, selected: section == 1, onTap: () => setState(() => section = 1)), _LibraryTab(label: 'Achats', count: widget.state.purchased.length, selected: section == 2, onTap: () => setState(() => section = 2))]))]))),
      SliverToBoxAdapter(child: books.isEmpty ? EmptyState(title: section == 0 ? 'Aucun favori' : section == 1 ? 'Rien dans votre liste' : 'Aucun achat', message: section == 0 ? 'Touchez le cœur d’un ouvrage pour le retrouver ici.' : section == 1 ? 'Ajoutez des documents à lire plus tard.' : 'Vos documents Premium achetés apparaîtront ici.', icon: section == 0 ? Icons.favorite_border_rounded : section == 1 ? Icons.bookmark_border_rounded : Icons.shopping_bag_outlined) : BookGrid(books: books, favorites: widget.state.favorites, onBook: widget.onBook, onFavorite: (book) => widget.state.toggleFavorite(book.id))),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ]);
  }
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
      borderRadius: BorderRadius.circular(11),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 10),
        decoration: BoxDecoration(color: selected ? AppColors.sky : Colors.transparent, borderRadius: BorderRadius.circular(11)),
        child: Text('$label ($count)', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? AppColors.blue : AppColors.muted)),
      ),
    ),
  );
}
