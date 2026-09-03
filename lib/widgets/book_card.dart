import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import 'document_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.favorite, required this.onTap, this.onFavorite, this.width = 166});
  final Book book;
  final bool favorite;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: Stack(children: [
          Positioned.fill(child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Color(0x220F172A), blurRadius: 14, offset: Offset(0, 7))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(15), child: DocumentCover(imageUrl: book.image)),
          )),
          if (book.isPremium) Positioned(left: 8, top: 8, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFE7A3), borderRadius: BorderRadius.circular(99)),
            child: const Text('PREMIUM', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFF755100))),
          )),
          if (onFavorite != null) Positioned(right: 7, top: 7, child: Material(
            color: Colors.white.withValues(alpha: .94), shape: const CircleBorder(),
            child: InkWell(customBorder: const CircleBorder(), onTap: onFavorite, child: SizedBox(width: 32, height: 32, child: Icon(AppIcons.heart, size: 17, color: favorite ? const Color(0xFFE5484D) : AppColors.ink))),
          )),
        ])),
        const SizedBox(height: 9),
        Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bookTitle(size: 13, weight: FontWeight.w900)),
        const SizedBox(height: 3),
        Text(book.author.isEmpty ? 'Auteur non renseigné' : book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: AppColors.muted, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Row(children: [
          Icon(AppIcons.star, size: 11, color: book.isPremium ? AppColors.gold : AppColors.blue),
          const SizedBox(width: 4),
          Text(book.rating > 0 ? book.rating.toStringAsFixed(1) : '${book.views} vues', style: const TextStyle(fontSize: 9.5, color: AppColors.muted)),
          if (book.isPremium && book.price > 0) ...[const Spacer(), Text('${book.price.toInt()} F', style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: AppColors.gold))],
        ]),
      ]),
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
    const gap = 16.0;
    final cardWidth = (constraints.maxWidth - 32 - gap * (columns - 1)) / columns;
    final extent = (cardWidth / .70 + 76).clamp(270.0, 340.0).toDouble();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, mainAxisExtent: extent, crossAxisSpacing: gap, mainAxisSpacing: 20),
      itemCount: books.length,
      itemBuilder: (_, i) => BookCard(book: books[i], favorite: favorites.contains(books[i].id), onTap: () => onBook(books[i]), onFavorite: onFavorite == null ? null : () => onFavorite!(books[i]), width: double.infinity),
    );
  });
}
