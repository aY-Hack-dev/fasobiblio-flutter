import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/brand_header.dart';
import '../widgets/section.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key, required this.state, required this.onBook});
  final AppState state; final ValueChanged<Book> onBook;
  @override Widget build(BuildContext context) {
    final books = state.books.where((b) => b.isPremium).toList();
    return CustomScrollView(slivers: [
      const SliverToBoxAdapter(child: BrandHeader(compact: true)),
      SliverToBoxAdapter(child: Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.all(24), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF231A47), Color(0xFF4C3575)]), borderRadius: BorderRadius.circular(26)), child: const Column(children: [Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD66B), size: 48), SizedBox(height: 9), Text('Fasobiblio Premium', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white)), SizedBox(height: 7), Text('Toute la bibliothèque avancée pour accélérer vos études et vos recherches.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFDCD4EC)))]))),
      if (state.offers.isNotEmpty) const SliverToBoxAdapter(child: SectionTitle('Choisissez votre formule')),
      if (state.offers.isNotEmpty) SliverToBoxAdapter(child: SizedBox(height: 145, child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), scrollDirection: Axis.horizontal, itemCount: state.offers.length, separatorBuilder: (_, __) => const SizedBox(width: 11), itemBuilder: (_, i) {
        final offer = state.offers[i] is Map ? Map<String, dynamic>.from(state.offers[i]) : <String, dynamic>{};
        final nameValue = offer['name']; final name = nameValue is Map ? '${nameValue['fr'] ?? (nameValue.values.isNotEmpty ? nameValue.values.first : 'Offre')}' : '${nameValue ?? offer['id'] ?? 'Offre'}';
        final priceValue = offer['price']; final price = priceValue is num ? priceValue.toInt() : int.tryParse('$priceValue') ?? 0;
        return Container(width: 225, padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFEAD9A7)), borderRadius: BorderRadius.circular(19)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, maxLines: 1, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)), const Spacer(), Text('$price FCFA', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gold)), Text(offer['lifetime'] == true ? 'Accès à vie' : '${offer['durationDays'] ?? 30} jours', style: const TextStyle(fontSize: 11, color: AppColors.muted))]));
      }))),
      SliverToBoxAdapter(child: SectionTitle('Collection Premium', action: '${books.length} titres')),
      SliverToBoxAdapter(child: books.isEmpty ? const EmptyState(title: 'La collection arrive', message: 'Les ouvrages Premium seront bientôt disponibles.') : BookGrid(books: books, favorites: state.favorites, onBook: onBook)),
      const SliverToBoxAdapter(child: SizedBox(height: 24)),
    ]);
  }
}
