import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/section.dart';
import 'payment_flow.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key, required this.state, required this.onBook});
  final AppState state;
  final ValueChanged<Book> onBook;

  @override
  Widget build(BuildContext context) {
    final books = state.books.where((b) => b.isPremium).toList();
    final active = state.subscription != null;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _PremiumHero(active: active, bookCount: books.length)),
        if (active) SliverToBoxAdapter(child: _ActiveStatus(subscription: state.subscription!)),
        if (state.offers.isNotEmpty) const SliverToBoxAdapter(child: SectionTitle('Choisissez votre formule')),
        if (state.offers.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 190,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.offers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final offer = state.offers[i] is Map ? Map<String, dynamic>.from(state.offers[i]) : <String, dynamic>{};
                  final nameValue = offer['name'];
                  final name = nameValue is Map ? '${nameValue['fr'] ?? (nameValue.values.isNotEmpty ? nameValue.values.first : 'Offre')}' : '${nameValue ?? offer['id'] ?? 'Offre'}';
                  final priceValue = offer['price'];
                  final price = priceValue is num ? priceValue.toInt() : int.tryParse('$priceValue') ?? 0;
                  return _OfferCard(name: name, price: price, lifetime: offer['lifetime'] == true, durationDays: int.tryParse('${offer['durationDays'] ?? 30}') ?? 30, featured: i == 0, onTap: () => purchaseSubscription(context, state, offer));
                },
              ),
            ),
          ),
        SliverToBoxAdapter(child: SectionTitle('Collection Premium', action: '${books.length} titres')),
        SliverToBoxAdapter(
          child: books.isEmpty
              ? const EmptyState(title: 'La collection arrive', message: 'Les ouvrages Premium seront bientôt disponibles.', icon: AppIcons.premium)
              : BookGrid(books: books, favorites: state.favorites, onBook: onBook, onFavorite: (book) => state.toggleFavorite(book.id)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.active, required this.bookCount});
  final bool active;
  final int bookCount;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0A1D3D), Color(0xFF123F8C), AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
      borderRadius: BorderRadius.circular(28),
      boxShadow: const [BoxShadow(color: Color(0x381860F0), blurRadius: 30, offset: Offset(0, 14))],
    ),
    child: Stack(children: [
      Positioned(right: -35, top: -55, child: Container(width: 170, height: 170, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .06), shape: BoxShape.circle))),
      Positioned(right: 8, bottom: -34, child: Icon(AppIcons.premium, size: 130, color: const Color(0xFFFFD166).withValues(alpha: .10))),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFFFD166).withValues(alpha: .15), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFFFD166).withValues(alpha: .35))), child: const Icon(AppIcons.premium, color: Color(0xFFFFD166), size: 27)),
          const Spacer(),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(999)), child: Text(active ? 'PREMIUM ACTIF' : '$bookCount TITRES', style: const TextStyle(fontSize: 9, letterSpacing: .8, fontWeight: FontWeight.w900, color: Colors.white))),
        ]),
        const SizedBox(height: 24),
        Text('Fasobiblio Premium', style: AppTypography.display(size: 28, weight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Accédez aux ressources avancées et construisez une bibliothèque qui vous accompagne vraiment dans vos études.', style: TextStyle(fontSize: 12, height: 1.5, color: Color(0xFFDCE7FF))),
        const SizedBox(height: 18),
        const Row(children: [Expanded(child: _BenefitChip(icon: AppIcons.bookOpen, label: 'Ressources premium')), SizedBox(width: 8), Expanded(child: _BenefitChip(icon: AppIcons.download, label: 'Lecture hors ligne'))]),
        const SizedBox(height: 8),
        const Row(children: [Expanded(child: _BenefitChip(icon: AppIcons.sparkles, label: 'Expérience complète')), SizedBox(width: 8), Expanded(child: _BenefitChip(icon: AppIcons.verified, label: 'Accès synchronisé'))]),
      ]),
    ]),
  );
}

class _BenefitChip extends StatelessWidget {
  const _BenefitChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    minHeight: 44,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .09), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [Icon(icon, size: 14, color: const Color(0xFFFFD166)), const SizedBox(width: 7), Expanded(child: Text(label, maxLines: 2, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)))]),
  );
}

class _ActiveStatus extends StatelessWidget {
  const _ActiveStatus({required this.subscription});
  final Map<String, dynamic> subscription;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 2), padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFFFFF8E3), border: Border.all(color: const Color(0xFFE7CE86)), borderRadius: BorderRadius.circular(19)),
    child: Row(children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)), child: const Icon(AppIcons.verified, color: AppColors.gold)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${subscription['planName'] ?? 'Premium actif'}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)), const SizedBox(height: 3), Text(subscription['lifetime'] == true ? 'Votre accès Premium est valable à vie.' : 'Votre abonnement Premium est actif.', style: const TextStyle(fontSize: 11, color: AppColors.muted))])),
    ]),
  );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({required this.name, required this.price, required this.lifetime, required this.durationDays, required this.featured, required this.onTap});
  final String name; final int price; final bool lifetime; final int durationDays; final bool featured; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: featured ? const Color(0xFF102C5C) : Theme.of(context).colorScheme.surface,
    borderRadius: BorderRadius.circular(21),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        width: 224,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(border: Border.all(color: featured ? const Color(0x55FFD166) : Theme.of(context).dividerColor.withValues(alpha: .55)), borderRadius: BorderRadius.circular(21), boxShadow: featured ? const [BoxShadow(color: Color(0x21102C5C), blurRadius: 18, offset: Offset(0, 10))] : null),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 15, weight: FontWeight.w900, color: featured ? Colors.white : AppColors.ink))), if (featured) const Icon(AppIcons.premium, size: 18, color: Color(0xFFFFD166))]),
          const Spacer(),
          Text('$price FCFA', style: AppTypography.display(size: 22, weight: FontWeight.w900, color: featured ? const Color(0xFFFFD166) : AppColors.blue)),
          const SizedBox(height: 3),
          Text(lifetime ? 'Accès à vie' : '$durationDays jours', style: TextStyle(fontSize: 11, color: featured ? const Color(0xFFCAD6EA) : AppColors.muted)),
          const SizedBox(height: 12),
          Row(children: [Text('Choisir cette offre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: featured ? Colors.white : AppColors.blue)), const Spacer(), Icon(AppIcons.arrowRight, size: 16, color: featured ? Colors.white : AppColors.blue)]),
        ]),
      ),
    ),
  );
}
