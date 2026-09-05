import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import 'document_cover.dart';

class BookCard extends StatelessWidget {
  const BookCard({super.key, required this.book, required this.favorite, required this.onTap, this.onFavorite, this.width = 166});
  final Book book; final bool favorite; final VoidCallback onTap; final VoidCallback? onFavorite; final double width;
  String get priceLabel { final value=book.price; final text=value==value.roundToDouble()?value.toInt().toString():value.toString(); return '$text F'; }
  @override Widget build(BuildContext context)=>SizedBox(width:width,child:Material(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(20),child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(20),child:Container(padding:const EdgeInsets.all(9),decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.blue.withValues(alpha:.13)),boxShadow:const[BoxShadow(color:Color(0x0D0F172A),blurRadius:12,offset:Offset(0,5))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
    Expanded(child:Stack(children:[Positioned.fill(child:ClipRRect(borderRadius:BorderRadius.circular(15),child:DocumentCover(imageUrl:book.image))),if(book.isPremium)Positioned(left:7,top:7,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:const Color(0xFFFFE7A3),borderRadius:BorderRadius.circular(99)),child:const Text('PREMIUM',style:TextStyle(fontSize:12,fontWeight:FontWeight.w900,color:Color(0xFF755100))))),if(onFavorite!=null)Positioned(right:7,top:7,child:Material(color:Colors.white.withValues(alpha:.94),shape:const CircleBorder(),child:InkWell(customBorder:const CircleBorder(),onTap:onFavorite,child:SizedBox(width:32,height:32,child:Icon(AppIcons.heart,size:17,color:favorite?const Color(0xFFE5484D):AppColors.blueDeep))))),Positioned(left:8,bottom:8,child:Container(padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),decoration:BoxDecoration(color:const Color(0xDD102C5C),borderRadius:BorderRadius.circular(99)),child:Row(children:[const Icon(Icons.remove_red_eye_outlined,size:12,color:Colors.white),const SizedBox(width:4),Text('${book.views}',style:const TextStyle(fontSize:12,color:Colors.white,fontWeight:FontWeight.w700))])))])),
    const SizedBox(height:9),Text(book.title,maxLines:2,overflow:TextOverflow.ellipsis,style:AppTypography.bookTitle(size:13,weight:FontWeight.w900)),const SizedBox(height:3),Text(book.author.isEmpty?'Auteur non renseigné':book.author,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(fontSize:12,color:AppColors.muted,fontWeight:FontWeight.w600)),const SizedBox(height:7),
    Row(children:[Expanded(child:Container(height:3,decoration:BoxDecoration(color:book.isPremium?AppColors.gold:AppColors.blue,borderRadius:BorderRadius.circular(99)))),if(book.isPremium&&book.price>0)...[const SizedBox(width:8),Text(priceLabel,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w900,color:AppColors.gold))]])
  ])))));
}
class BookGrid extends StatefulWidget {
 const BookGrid({super.key,required this.books,required this.favorites,required this.onBook,this.onFavorite});final List<Book> books;final Set<String> favorites;final ValueChanged<Book> onBook;final ValueChanged<Book>? onFavorite;
 @override State<BookGrid> createState()=>_BookGridState();
}
class _BookGridState extends State<BookGrid> {
 int visible=24;
 List<Book> get books=>widget.books;
 Set<String> get favorites=>widget.favorites;
 ValueChanged<Book> get onBook=>widget.onBook;
 ValueChanged<Book>? get onFavorite=>widget.onFavorite;
 @override void didUpdateWidget(covariant BookGrid oldWidget){super.didUpdateWidget(oldWidget);if(oldWidget.books.length!=books.length)visible=24;}
 @override Widget build(BuildContext context)=>LayoutBuilder(builder:(context,constraints){final columns=constraints.maxWidth>=650?4:constraints.maxWidth>=470?3:2;const gap=14.0;final cardWidth=(constraints.maxWidth-32-gap*(columns-1))/columns;final extent=(cardWidth/.70+82).clamp(276.0,350.0).toDouble();return Column(children:[GridView.builder(shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),padding:const EdgeInsets.symmetric(horizontal:16,vertical:6),gridDelegate:SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:columns,mainAxisExtent:extent,crossAxisSpacing:gap,mainAxisSpacing:16),itemCount:books.length<visible?books.length:visible,itemBuilder:(_,i)=>BookCard(book:books[i],favorite:favorites.contains(books[i].id),onTap:()=>onBook(books[i]),onFavorite:onFavorite==null?null:()=>onFavorite!(books[i]),width:double.infinity)),if(books.length>visible)TextButton(onPressed:()=>setState(()=>visible+=24),child:const Text('Afficher plus'))]);});
}
