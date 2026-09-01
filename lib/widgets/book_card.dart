import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../models/book.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.favorite, required this.onTap, this.width = 150});
  final Book book;
  final bool favorite;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AspectRatio(aspectRatio: .7, child: Stack(fit: StackFit.expand, children: [
              ClipRRect(borderRadius: BorderRadius.circular(12), child: _Cover(book: book)),
              if (book.isPremium) Positioned(left: 7, top: 7, child: _Badge(text: 'PREMIUM', gold: true)),
              Positioned(right: 7, top: 7, child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 17, color: favorite ? Colors.red : AppColors.muted))),
            ])),
            const SizedBox(height: 10),
            Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, height: 1.22, fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 4),
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            const Spacer(),
            Row(children: [const Icon(Icons.visibility_outlined, size: 14, color: AppColors.muted), const SizedBox(width: 4), Text('${book.views}', style: const TextStyle(fontSize: 10, color: AppColors.muted)), const Spacer(), if (book.isPremium) Text('${book.price.toInt()} F', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.gold))]),
          ]),
        ),
      ),
    ),
  );
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book}); final Book book;
  @override Widget build(BuildContext context) => book.image.isEmpty
    ? Container(color: AppColors.sky, alignment: Alignment.center, padding: const EdgeInsets.all(12), child: const Text('FASOBIBLIO', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.blue)))
    : CachedNetworkImage(imageUrl: book.image, fit: BoxFit.cover, placeholder: (_, __) => Container(color: AppColors.sky, alignment: Alignment.center, child: const CircularProgressIndicator(strokeWidth: 2)), errorWidget: (_, __, ___) => Container(color: AppColors.sky, alignment: Alignment.center, child: const Icon(Icons.menu_book_rounded, size: 38, color: AppColors.blue)));
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.gold = false}); final String text; final bool gold;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), decoration: BoxDecoration(color: gold ? const Color(0xFFFFEAB0) : AppColors.sky, borderRadius: BorderRadius.circular(7)), child: Text(text, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: gold ? const Color(0xFF815700) : AppColors.blue)));
}

class BookGrid extends StatelessWidget {
  const BookGrid({super.key, required this.books, required this.favorites, required this.onBook});
  final List<Book> books; final Set<String> favorites; final ValueChanged<Book> onBook;
  @override Widget build(BuildContext context) => GridView.builder(
    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 304, crossAxisSpacing: 12, mainAxisSpacing: 12),
    itemCount: books.length, itemBuilder: (_, i) => BookCard(book: books[i], favorite: favorites.contains(books[i].id), onTap: () => onBook(books[i]), width: double.infinity),
  );
}
