import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../widgets/book_card.dart';
import '../widgets/section.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.state, required this.onBook});
  final AppState state;
  final ValueChanged<Book> onBook;
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}
class _LibraryScreenState extends State<LibraryScreen> {
  int section = 0;
  @override Widget build(BuildContext context) {
    final ids = section == 0 ? widget.state.favorites : section == 1 ? widget.state.later : widget.state.purchased;
    final books = widget.state.books.where((b) => ids.contains(b.id)).toList();
    final total = widget.state.favorites.length + widget.state.later.length + widget.state.purchased.length;
    return CustomScrollView(slivers: [
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18,18,18,4), child: Row(children:[Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Ma bibliothèque',style:AppTypography.display(size:22,weight:FontWeight.w900)),const SizedBox(height:4),const Text('Retrouvez tout ce que vous avez gardé.',style:TextStyle(fontSize:10.5,color:AppColors.muted))])),Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:7),decoration:BoxDecoration(color:AppColors.sky,borderRadius:BorderRadius.circular(12)),child:Text('$total docs',style:const TextStyle(fontSize:9.5,fontWeight:FontWeight.w900,color:AppColors.blue)))]))),
      SliverToBoxAdapter(child: _SegmentedLibrary(section: section,favorites: widget.state.favorites.length,later: widget.state.later.length,purchased: widget.state.purchased.length,onChanged: (value) => setState(() => section = value))),
      SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.fromLTRB(18,18,18,8),child: Row(children:[Expanded(child:Text(section==0?'Mes favoris':section==1?'À lire plus tard':'Mes achats',style:Theme.of(context).textTheme.titleLarge)),Text('${books.length}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.w900,color:AppColors.blueDeep))]))),
      SliverToBoxAdapter(child: books.isEmpty ? EmptyState(title:section==0?'Aucun favori':section==1?'Votre liste est vide':'Aucun achat',message:section==0?'Touchez le cœur d’un ouvrage pour le retrouver ici.':section==1?'Enregistrez des documents pour les lire plus tard.':'Vos documents Premium achetés apparaîtront ici.',icon:section==0?AppIcons.heart:section==1?AppIcons.bookmark:AppIcons.shoppingBag) : BookGrid(books:books,favorites:widget.state.favorites,onBook:widget.onBook,onFavorite:(book)=>widget.state.toggleFavorite(book.id))),
      const SliverToBoxAdapter(child:SizedBox(height:34)),
    ]);
  }
}
class _SegmentedLibrary extends StatelessWidget {
  const _SegmentedLibrary({required this.section,required this.favorites,required this.later,required this.purchased,required this.onChanged});final int section,favorites,later,purchased;final ValueChanged<int> onChanged;
  @override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.fromLTRB(16,14,16,0),child:Container(padding:const EdgeInsets.all(4),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(16),border:Border.all(color:Theme.of(context).dividerColor.withValues(alpha:.45))),child:Row(children:[_LibraryTab(label:'Favoris',count:favorites,selected:section==0,onTap:()=>onChanged(0)),_LibraryTab(label:'À lire',count:later,selected:section==1,onTap:()=>onChanged(1)),_LibraryTab(label:'Achats',count:purchased,selected:section==2,onTap:()=>onChanged(2))])));
}
class _LibraryTab extends StatelessWidget {
 const _LibraryTab({required this.label,required this.count,required this.selected,required this.onTap});final String label;final int count;final bool selected;final VoidCallback onTap;
 @override Widget build(BuildContext context)=>Expanded(child:InkWell(onTap:onTap,borderRadius:BorderRadius.circular(12),child:AnimatedContainer(duration:const Duration(milliseconds:170),padding:const EdgeInsets.symmetric(vertical:10,horizontal:4),decoration:BoxDecoration(color:selected?AppColors.blueDeep:Colors.transparent,borderRadius:BorderRadius.circular(12)),child:Text('$label  $count',textAlign:TextAlign.center,maxLines:1,overflow:TextOverflow.ellipsis,style:TextStyle(fontSize:10,fontWeight:FontWeight.w900,color:selected?Colors.white:AppColors.muted)))));
}
