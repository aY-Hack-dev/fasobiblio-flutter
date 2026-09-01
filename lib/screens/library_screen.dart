import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/brand_header.dart';
import '../widgets/section.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.state, required this.onBook});
  final AppState state; final ValueChanged<Book> onBook;
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> {
  bool favorites = true;
  @override Widget build(BuildContext context) {
    final ids = favorites ? widget.state.favorites : widget.state.later;
    final books = widget.state.books.where((b) => ids.contains(b.id)).toList();
    return CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: BrandHeader(compact: true)),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Ma bibliothèque', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 5), const Text('Retrouvez vos lectures personnelles.', style: TextStyle(color: AppColors.muted)), const SizedBox(height: 18), SegmentedButton<bool>(segments: [ButtonSegment(value: true, icon: const Icon(Icons.favorite_border_rounded), label: Text('Favoris (${widget.state.favorites.length})')), ButtonSegment(value: false, icon: const Icon(Icons.bookmark_border_rounded), label: Text('À lire (${widget.state.later.length})'))], selected: {favorites}, onSelectionChanged: (v) => setState(() => favorites = v.first), showSelectedIcon: false)]))),
      SliverToBoxAdapter(child: books.isEmpty ? EmptyState(title: favorites ? 'Aucun favori' : 'Rien dans votre liste', message: favorites ? 'Touchez le cœur d’un ouvrage pour le retrouver ici.' : 'Ajoutez des documents à lire plus tard.', icon: favorites ? Icons.favorite_border_rounded : Icons.bookmark_border_rounded) : BookGrid(books: books, favorites: widget.state.favorites, onBook: widget.onBook)),
      const SliverToBoxAdapter(child: SizedBox(height: 30)),
    ]);
  }
}
