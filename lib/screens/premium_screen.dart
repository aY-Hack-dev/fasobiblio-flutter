import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/document_skeleton.dart';
import '../widgets/section.dart';
import 'payment_flow.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key, required this.state, required this.onBook});

  final AppState state;
  final ValueChanged<Book> onBook;

  @override
  Widget build(BuildContext context) {
    final books = state.books.where((b) => b.isPremium).toList();

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PremiumIntro(
            active: state.subscription != null,
            count: books.length,
          ),
        ),
        if (state.subscription != null)
          SliverToBoxAdapter(
            child: _ActiveStatus(subscription: state.subscription!),
          ),
        if (state.offers.isNotEmpty)
          const SliverToBoxAdapter(
            child: SectionTitle('Choisissez votre formule'),
          ),
        if (state.offers.isNotEmpty)
          SliverToBoxAdapter(
            child: SizedBox(
              height: 112,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: state.offers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 9),
                itemBuilder: (context, i) {
                  final offer = state.offers[i] is Map
                      ? Map<String, dynamic>.from(state.offers[i])
                      : <String, dynamic>{};
                  final nv = offer['name'];
                  final name = nv is Map
                      ? '${nv['fr'] ?? (nv.values.isNotEmpty ? nv.values.first : 'Offre')}'
                      : '${nv ?? offer['id'] ?? 'Offre'}';
                  final pv = offer['price'];
                  final price = pv is num ? pv.toInt() : int.tryParse('$pv') ?? 0;

                  return _OfferCard(
                    name: name,
                    price: price,
                    lifetime: offer['lifetime'] == true,
                    durationDays:
                        int.tryParse('${offer['durationDays'] ?? 30}') ?? 30,
                    featured: i == 0,
                    onTap: () => purchaseSubscription(context, state, offer),
                  );
                },
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: SectionTitle(
            'Collection Premium',
            action: '${books.length} titres',
          ),
        ),
        SliverToBoxAdapter(
          child: state.catalogPending ? DocumentSkeleton(state: state) : books.isEmpty
              ? const EmptyState(
                  title: 'La collection arrive',
                  message: 'Les ouvrages Premium seront bientôt disponibles.',
                  icon: AppIcons.premium,
                )
              : BookGrid(
                  books: books,
                  favorites: state.favorites,
                  onBook: onBook,
                  onFavorite: (b) => state.toggleFavorite(b.id),
                ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _PremiumIntro extends StatelessWidget {
  const _PremiumIntro({required this.active, required this.count});

  final bool active;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5D6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    AppIcons.premium,
                    color: AppColors.gold,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fasobiblio Premium',
                        style: AppTypography.display(
                          size: 20,
                          weight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Des ressources choisies pour aller plus loin.',
                        style: TextStyle(
                          fontSize:12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5D6),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    active ? 'ACTIF' : '$count TITRES',
                    style: const TextStyle(
                      fontSize:12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            const Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                _Benefit(
                  icon: AppIcons.bookOpen,
                  label: 'Ressources premium',
                ),
                _Benefit(icon: AppIcons.download, label: 'Hors ligne'),
                _Benefit(
                  icon: AppIcons.sparkles,
                  label: 'Expérience complète',
                ),
                _Benefit(icon: AppIcons.verified, label: 'Synchronisé'),
              ],
            ),
          ],
        ),
      );
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppColors.gold.withValues(alpha: .22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.gold),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize:12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}

class _ActiveStatus extends StatelessWidget {
  const _ActiveStatus({required this.subscription});

  final Map<String, dynamic> subscription;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E3),
          border: Border.all(color: const Color(0xFFE7CE86)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(AppIcons.verified, color: AppColors.gold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${subscription['planName'] ?? 'Premium actif'}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      );
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.name,
    required this.price,
    required this.lifetime,
    required this.durationDays,
    required this.featured,
    required this.onTap,
  });

  final String name;
  final int price;
  final bool lifetime;
  final int durationDays;
  final bool featured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: featured
            ? const Color(0xFF102C5C)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Container(
            width: 150,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              border: Border.all(
                color: featured
                    ? const Color(0x55FFD166)
                    : Theme.of(context)
                        .dividerColor
                        .withValues(alpha: .55),
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.display(
                    size: 11.5,
                    weight: FontWeight.w900,
                    color: featured
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '$price FCFA',
                  style: AppTypography.display(
                    size: 16,
                    weight: FontWeight.w900,
                    color: featured
                        ? const Color(0xFFFFD166)
                        : AppColors.blue,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lifetime ? 'Accès à vie' : '$durationDays jours',
                        style: TextStyle(
                          fontSize:12,
                          color: featured
                              ? const Color(0xFFCAD6EA)
                              : AppColors.muted,
                        ),
                      ),
                    ),
                    Icon(
                      AppIcons.arrowRight,
                      size: 14,
                      color: featured ? Colors.white : AppColors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
