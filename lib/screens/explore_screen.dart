import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.state, required this.onBook, required this.onAssistant});
  final AppState state; final ValueChanged<Book> onBook; final VoidCallback onAssistant;
  @override State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '', category = '';
  @override Widget build(BuildContext context) {
    final categories = widget.state.books.map((b) => b.category).toSet().toList()..sort();
    final q = query.toLowerCase().trim();
    final results = widget.state.books.where((b) => (category.isEmpty || b.category == category) && (q.isEmpty || '${b.title} ${b.author} ${b.description}'.toLowerCase().contains(q))).take(150).toList();
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 4, 20, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Explorer', style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 5), const Text('Trouvez la bonne ressource, au bon moment.', style: TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18), TextField(onChanged: (v) => setState(() => query = v), decoration: const InputDecoration(prefixIcon: Icon(AppIcons.search), hintText: 'Titre, auteur, matière…')),
        const SizedBox(height: 14), Material(color: AppColors.sky, borderRadius: BorderRadius.circular(18), child: InkWell(onTap: widget.onAssistant, borderRadius: BorderRadius.circular(18), child: const Padding(padding: EdgeInsets.all(14), child: Row(children: [CircleAvatar(backgroundColor: AppColors.blue, foregroundColor: Colors.white, child: Icon(AppIcons.sparkles, size: 20)), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Assistant de recherche', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink)), Text('Décrivez votre besoin, l’IA vous oriente.', style: TextStyle(fontSize: 11, color: AppColors.muted))])), Icon(AppIcons.chevronRight, color: AppColors.blue)])))),
      ]))),
      SliverToBoxAdapter(child: SizedBox(height: 43, child: ListView(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, children: [FilterChip(label: const Text('Tous'), selected: category.isEmpty, onSelected: (_) => setState(() => category = '')), const SizedBox(width: 8), ...categories.map((c) => Padding(padding: const EdgeInsets.only(right: 8), child: FilterChip(label: Text(categoryLabel(c)), selected: category == c, onSelected: (_) => setState(() => category = c))))]))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 8), child: Text('${results.length} document${results.length > 1 ? 's' : ''}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted)))),
      SliverToBoxAdapter(child: results.isEmpty ? const Padding(padding: EdgeInsets.all(40), child: Center(child: Text('Aucun document ne correspond à cette recherche.'))) : BookGrid(books: results, favorites: widget.state.favorites, onBook: widget.onBook, onFavorite: (book) => widget.state.toggleFavorite(book.id))),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}
