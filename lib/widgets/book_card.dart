import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import 'document_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.favorite,
    required this.onTap,
    this.onFavorite,
    this.width = 166,
  });

  final Book book;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final double width;

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return SizedBox(
      width: width,
      child: Material(
        color: surface,
        elevation: 0,
        shadowColor: const Color(0x24113A78),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.blue.withValues(alpha: .10)),
              boxShadow: const [
                BoxShadow(color: Color(0x101860F0), blurRadius: 18, offset: Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: DocumentCover(imageUrl: book.image),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0x12000000), Colors.transparent, Color(0x3606152E)],
                                stops: [0, .55, 1],
                              ),
                            ),
                          ),
                        ),
                        if (book.isPremium)
                          const Positioned(
                            left: 8,
                            top: 8,
                            child: _Badge(text: 'PREMIUM', gold: true),
                          ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Material(
                            color: Colors.white.withValues(alpha: .94),
                            elevation: 2,
                            shadowColor: const Color(0x26000000),
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onFavorite,
                              child: SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  AppIcons.heart,
                                  size: 18,
                                  color: favorite ? const Color(0xFFE5484D) : AppColors.blueDeep,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 9,
                          child: Row(
                            children: [
                              _MiniPill(
                                icon: AppIcons.eye,
                                label: book.views > 999 ? '${(book.views / 1000).toStringAsFixed(1)}k' : '${book.views}',
                              ),
                              const SizedBox(width: 6),
                              _MiniPill(
                                icon: AppIcons.star,
                                label: book.rating > 0 ? book.rating.toStringAsFixed(1) : 'Nouveau',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bookTitle(size: 13.5, weight: FontWeight.w900),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.author.isEmpty ? 'Auteur non renseigné' : book.author,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: AppColors.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(99),
                                gradient: const LinearGradient(colors: [AppColors.blueDeep, AppColors.blue]),
                              ),
                            ),
                          ),
                          if (book.isPremium) ...[
                            const SizedBox(width: 10),
                            Text(
                              book.price > 0 ? '${book.price.toInt()} F' : 'Premium',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.gold),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xD90A234F),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: const Color(0x25FFFFFF)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.gold = false});
  final String text;
  final bool gold;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: gold ? const Color(0xFFFFE7A3) : AppColors.sky,
          borderRadius: BorderRadius.circular(99),
          boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 8,
            letterSpacing: .5,
            fontWeight: FontWeight.w900,
            color: gold ? const Color(0xFF755100) : AppColors.blue,
          ),
        ),
      );
}

class BookGrid extends StatelessWidget {
  const BookGrid({super.key, required this.books, required this.favorites, required this.onBook, this.onFavorite});
  final List<Book> books;
  final Set<String> favorites;
  final ValueChanged<Book> onBook;
  final ValueChanged<Book>? onFavorite;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 4 : constraints.maxWidth >= 470 ? 3 : 2;
        const gap = 13.0;
        final cardWidth = (constraints.maxWidth - 32 - gap * (columns - 1)) / columns;
        final extent = ((cardWidth - 20) / .70 + 112).clamp(302.0, 352.0).toDouble();
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisExtent: extent,
            crossAxisSpacing: gap,
            mainAxisSpacing: gap,
          ),
          itemCount: books.length,
          itemBuilder: (_, i) => BookCard(
            book: books[i],
            favorite: favorites.contains(books[i].id),
            onTap: () => onBook(books[i]),
            onFavorite: onFavorite == null ? null : () => onFavorite!(books[i]),
            width: double.infinity,
          ),
        );
      });
}
