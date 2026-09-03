import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, required this.state, required this.onBook, required this.onAssistant});
  final AppState state;
  final ValueChanged<Book> onBook;
  final VoidCallback onAssistant;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String query = '';
  String category = '';

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.books.map((b) => b.category).where((c) => c.isNotEmpty).toSet().toList()..sort();
    final q = query.toLowerCase().trim();
    final results = widget.state.books.where((b) {
      final matchesCategory = category.isEmpty || b.category == category;
      final matchesQuery = q.isEmpty || '${b.title} ${b.author} ${b.description}'.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).take(150).toList();

    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: _ExploreHero(
        count: widget.state.books.length,
        onAssistant: widget.onAssistant,
        onQueryChanged: (value) => setState(() => query = value),
      )),
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Parcourir les rayons', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 3),
            const Text('Affinez votre recherche par catégorie.', style: TextStyle(fontSize: 11.5, color: AppColors.muted)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(12)),
            child: Text('${results.length} résultat${results.length > 1 ? 's' : ''}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.blue)),
          ),
        ]),
      )),
      SliverToBoxAdapter(child: SizedBox(
        height: 48,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          children: [
            _CategoryPill(label: 'Tous', selected: category.isEmpty, onTap: () => setState(() => category = '')),
            const SizedBox(width: 8),
            ...categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _CategoryPill(label: categoryLabel(c), selected: category == c, onTap: () => setState(() => category = c)),
            )),
          ],
        ),
      )),
      const SliverToBoxAdapter(child: SizedBox(height: 12)),
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
      const SliverToBoxAdapter(child: SizedBox(height: 32)),
    ]);
  }
}

class _ExploreHero extends StatelessWidget {
  const _ExploreHero({required this.count, required this.onAssistant, required this.onQueryChanged});
  final int count;
  final VoidCallback onAssistant;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [AppColors.blueDeep, AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x331860F0), blurRadius: 26, offset: Offset(0, 14))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Trouvez exactement ce qu’il vous faut.', style: AppTypography.display(size: 24, weight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 7),
          Text('$count ressources disponibles dans la bibliothèque Fasobiblio.', style: const TextStyle(fontSize: 12, height: 1.45, color: Color(0xFFDDE8FF))),
        ])),
        const SizedBox(width: 14),
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: const Color(0x22FFFFFF), borderRadius: BorderRadius.circular(16)),
          child: const Icon(AppIcons.search, color: Colors.white, size: 24),
        ),
      ]),
      const SizedBox(height: 18),
      TextField(
        onChanged: onQueryChanged,
        decoration: InputDecoration(
          hintText: 'Titre, auteur, matière…',
          prefixIcon: const Icon(AppIcons.search, color: AppColors.blue),
          suffixIcon: const Icon(AppIcons.filters, color: AppColors.muted),
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blueDeep, width: 1.2)),
        ),
      ),
      const SizedBox(height: 12),
      Material(
        color: const Color(0x18FFFFFF),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onAssistant,
          borderRadius: BorderRadius.circular(18),
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(backgroundColor: Colors.white, foregroundColor: AppColors.blue, child: Icon(AppIcons.sparkles, size: 20)),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Assistant de recherche', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
                SizedBox(height: 2),
                Text('Décrivez votre besoin, l’IA vous oriente.', style: TextStyle(fontSize: 11, color: Color(0xFFDDE8FF))),
              ])),
              Icon(AppIcons.chevronRight, color: Colors.white),
            ]),
          ),
        ),
      ),
    ]),
  );
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.blue : Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.blue : Theme.of(context).dividerColor.withValues(alpha: .65)),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: selected ? Colors.white : AppColors.muted)),
      ),
    ),
  );
}

class _EmptySearch extends StatelessWidget {
  const _EmptySearch();

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .55)),
    ),
    child: const Column(children: [
      CircleAvatar(radius: 28, backgroundColor: AppColors.sky, child: Icon(AppIcons.search, color: AppColors.blue)),
      SizedBox(height: 14),
      Text('Aucun document trouvé', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
      SizedBox(height: 6),
      Text('Essayez un autre mot-clé ou choisissez une autre catégorie.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.45, color: AppColors.muted)),
    ]),
  );
}
