import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import 'document_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.favorite, required this.onTap, this.onFavorite, this.width = 156});
  final Book book;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 1,
      shadowColor: const Color(0x160F172A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: .7, child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(10), child: DocumentCover(imageUrl: book.image)),
              if (book.isPremium) Positioned(left: 7, top: 7, child: _Badge(text: 'PREMIUM', gold: true)),
              Positioned(right: 7, top: 7, child: Material(color: Theme.of(context).colorScheme.surface, shape: const CircleBorder(), elevation: 1, child: InkWell(customBorder: const CircleBorder(), onTap: onFavorite, child: SizedBox(width: 32, height: 32, child: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 18, color: favorite ? const Color(0xFFE5484D) : AppColors.muted))))),
            ])),
            const SizedBox(height: 10),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 13, weight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const Spacer(),
            const Divider(height: 12, thickness: 1, color: AppColors.line),
            Row(children: [const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF4B740)), const SizedBox(width: 3), Text(book.rating > 0 ? book.rating.toStringAsFixed(1) : 'Nouveau', style: const TextStyle(fontSize: 10, color: AppColors.muted)), const Spacer(), if (book.isPremium) Text(book.price > 0 ? '${book.price.toInt()} F' : 'Premium', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gold))]),
          ]),
        ),
      ),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.gold = false}); final String text; final bool gold;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: gold ? const Color(0xFFFFEAB0) : AppColors.sky, borderRadius: BorderRadius.circular(7)), child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: gold ? const Color(0xFF815700) : AppColors.blue)));
}

class BookGrid extends StatelessWidget {
  const BookGrid({super.key, required this.books, required this.favorites, required this.onBook, this.onFavorite});
  final List<Book> books; final Set<String> favorites; final ValueChanged<Book> onBook; final ValueChanged<Book>? onFavorite;
  @override Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 312, crossAxisSpacing: 12, mainAxisSpacing: 12),
    itemCount: books.length, itemBuilder: (_, i) => BookCard(book: books[i], favorite: favorites.contains(books[i].id), onTap: () => onBook(books[i]), onFavorite: onFavorite == null ? null : () => onFavorite!(books[i]), width: double.infinity),
  );
}
