import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/theme.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../services/document_service.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book, required this.state});
  final Book book; final AppState state;
  @override State<BookDetailScreen> createState() => _BookDetailScreenState();
}
class _BookDetailScreenState extends State<BookDetailScreen> {
  final documents = DocumentService(); bool busy = false; double? progress;
  Future<void> open(String mode) async {
    if (widget.book.isPremium) { if (mounted) showDialog(context: context, builder: (_) => AlertDialog(icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 38), title: const Text('Document Premium'), content: Text('Cet ouvrage est proposé à ${widget.book.price.toInt()} FCFA. Activez une offre Premium depuis l’onglet dédié.'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Compris'))])); return; }
    setState(() { busy = true; progress = 0; });
    try {
      final cacheKey = '${widget.book.id}-${widget.book.title}';
      final cached = await documents.cached(cacheKey);
      String path;
      String name = widget.book.title;
      if (cached != null) {
        path = cached;
      } else {
        final file = await widget.state.api.documentFile(widget.book.id, mode);
        if ((file['url'] ?? '').isEmpty) throw Exception('Le fichier est momentanément indisponible.');
        name = file['name'] ?? widget.book.title;
        path = await documents.ensureLocal(file['url']!, cacheKey, onProgress: (value) { if (mounted) setState(() => progress = value); });
      }
      if (!mounted) return;
      if (mode == 'read') {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfReaderScreen(path: path, title: widget.book.title)));
      } else {
        final destination = await documents.exportToDownloads(path, name);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Enregistré dans $destination')));
      }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', '')))); }
    finally { if (mounted) setState(() { busy = false; progress = null; }); }
  }
  @override Widget build(BuildContext context) {
    final b = widget.book; final fav = widget.state.favorites.contains(b.id); final later = widget.state.later.contains(b.id);
    return Scaffold(
      appBar: AppBar(title: const Text('Détail du document'), actions: [IconButton(onPressed: () => SharePlus.instance.share(ShareParams(text: '${b.title}\nhttps://fasobiblio.com/?doc=${b.id}')), icon: const Icon(Icons.ios_share_rounded))]),
      bottomNavigationBar: SafeArea(child: Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.line))), child: Row(children: [Expanded(child: FilledButton.icon(onPressed: busy ? null : () => open('read'), icon: const Icon(Icons.menu_book_rounded), label: Text(b.isPremium ? 'Débloquer / Lire' : 'Lire maintenant'))), const SizedBox(width: 9), IconButton.filledTonal(onPressed: busy ? null : () => open('download'), icon: const Icon(Icons.download_rounded), tooltip: 'Télécharger')]))),
      body: Stack(children: [ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 35), children: [
        Center(child: Hero(tag: 'book-${b.id}', child: ClipRRect(borderRadius: BorderRadius.circular(18), child: b.image.isEmpty ? Container(width: 190, height: 270, color: AppColors.sky, alignment: Alignment.center, child: const Icon(Icons.menu_book_rounded, size: 55, color: AppColors.blue)) : Image.network(b.image, width: 190, height: 270, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 190, height: 270, color: AppColors.sky, child: const Icon(Icons.menu_book_rounded, color: AppColors.blue)))))),
        const SizedBox(height: 19), Text(b.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium), const SizedBox(height: 7), Text(b.author, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 20), Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: AppColors.line)), child: Row(children: [_Stat('${b.views}', 'Lectures'), _Stat('${b.downloads}', 'Téléch.'), _Stat(categoryLabel(b.category), 'Rayon')])),
        const SizedBox(height: 17), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_Action(icon: fav ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: fav ? 'Favori' : 'Ajouter', active: fav, onTap: () => widget.state.toggleFavorite(b.id)), _Action(icon: later ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: 'À lire', active: later, onTap: () => widget.state.toggleLater(b.id)), _Action(icon: Icons.share_outlined, label: 'Partager', onTap: () => SharePlus.instance.share(ShareParams(text: '${b.title}\nhttps://fasobiblio.com/?doc=${b.id}')))]),
        if (b.description.isNotEmpty) ...[const SizedBox(height: 25), const Text('À propos de cet ouvrage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.ink)), const SizedBox(height: 10), Text(b.description, style: const TextStyle(height: 1.55, color: AppColors.ink))],
        const SizedBox(height: 22), Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.line), borderRadius: BorderRadius.circular(17)), child: Column(children: [_Info('Langue', b.language.toUpperCase()), _Info('Niveau', b.level.isEmpty ? 'Tous niveaux' : b.level), _Info('Année', b.year.isEmpty ? 'Non précisée' : b.year, last: true)])),
      ]), if (busy) Positioned.fill(child: ColoredBox(color: const Color(0x66000000), child: Center(child: Container(width: 240, padding: const EdgeInsets.all(23), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(value: progress == 0 ? null : progress), const SizedBox(height: 13), Text(progress == 0 ? 'Préparation du document…' : 'Téléchargement ${((progress ?? 0) * 100).round()} %', style: const TextStyle(fontWeight: FontWeight.w800))])))))]),
    );
  }
}
class _Stat extends StatelessWidget { const _Stat(this.value, this.label); final String value, label; @override Widget build(BuildContext context) => Expanded(child: Column(children: [Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.ink)), Text(label, style: const TextStyle(fontSize: 10, color: AppColors.muted))])); }
class _Action extends StatelessWidget { const _Action({required this.icon, required this.label, required this.onTap, this.active = false}); final IconData icon; final String label; final VoidCallback onTap; final bool active; @override Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30), child: Padding(padding: const EdgeInsets.all(7), child: Column(children: [CircleAvatar(backgroundColor: active ? AppColors.blue : Colors.white, foregroundColor: active ? Colors.white : AppColors.ink, child: Icon(icon, size: 20)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted))]))); }
class _Info extends StatelessWidget { const _Info(this.label, this.value, {this.last = false}); final String label, value; final bool last; @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(border: last ? null : const Border(bottom: BorderSide(color: AppColors.line))), child: Row(children: [Text(label, style: const TextStyle(color: AppColors.muted)), const Spacer(), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink))])); }
