import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../models/app_notification.dart';
import '../models/book.dart';
import '../services/app_state.dart';
import '../services/document_service.dart';
import 'auth_sheet.dart';
import 'payment_flow.dart';
import 'pdf_reader_screen.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.book, required this.state});
  final Book book;
  final AppState state;
  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  final documents = DocumentService();
  List<DocumentReview> reviews = [];
  bool busy = false;
  bool loadingReviews = false;
  double? progress;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    if (widget.state.offline) return;
    setState(() => loadingReviews = true);
    try {
      final values = await widget.state.api.reviews(widget.book.id);
      if (!mounted) return;
      setState(() => reviews = values.where((item) => item.status == 'approved').toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
    } catch (_) {
      // Les informations principales restent utilisables si les avis ne répondent pas.
    } finally {
      if (mounted) setState(() => loadingReviews = false);
    }
  }

  Future<void> open(String mode) async {
    final cacheKey = '${widget.book.id}-${widget.book.title}';
    final cached = await documents.cached(cacheKey);
    if (cached == null && !requireInternet(context, widget.state)) return;
    if (widget.book.isPremium && !widget.state.hasAccess(widget.book)) {
      if (!requireInternet(context, widget.state)) return;
      final unlocked = await purchaseDocument(context, widget.state, widget.book);
      if (unlocked && mounted) await open(mode);
      return;
    }
    setState(() { busy = true; progress = 0; });
    try {
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
        if (mounted) showToast(context, 'Document enregistré dans $destination.', success: true);
      }
    } catch (error) {
      if (mounted) showToast(context, friendlyFailure(error, action: mode == 'read' ? 'ouvrir ce document' : 'télécharger ce document'));
    } finally {
      if (mounted) setState(() { busy = false; progress = null; });
    }
  }

  Future<void> _writeReview() async {
    if (!requireInternet(context, widget.state)) return;
    final session = widget.state.session;
    if (session == null || session.anonymous) {
      showToast(context, 'Connectez-vous pour publier un avis.');
      await showAuthSheet(context, widget.state, signup: false);
      return;
    }
    final result = await showModalBottomSheet<_ReviewDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ReviewSheet(),
    );
    if (result == null || !mounted) return;
    try {
      await widget.state.api.submitReview(widget.book.id, result.stars, result.comment);
      if (mounted) showToast(context, 'Merci ! Votre avis sera visible après validation.', success: true);
    } catch (error) {
      if (mounted) showToast(context, friendlyFailure(error, action: 'publier votre avis'));
    }
  }

  double get averageRating {
    if (reviews.isEmpty) return widget.book.rating;
    return reviews.fold<int>(0, (sum, item) => sum + item.stars) / reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.book;
    final favorite = widget.state.favorites.contains(book.id);
    final later = widget.state.later.contains(book.id);
    final surface = Theme.of(context).colorScheme.surface;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail du document'),
        actions: [IconButton(onPressed: () => SharePlus.instance.share(ShareParams(text: '${book.title}\nhttps://fasobiblio.com/?doc=${book.id}')), icon: const Icon(Icons.ios_share_rounded), tooltip: 'Partager')],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: surface, border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .5)))),
          child: Row(children: [
            Expanded(child: FilledButton.icon(onPressed: busy ? null : () => open('read'), icon: const Icon(Icons.auto_stories_rounded), label: Text(book.isPremium && !widget.state.hasAccess(book) ? 'Débloquer et lire' : 'Lire maintenant'))),
            const SizedBox(width: 9),
            IconButton.filledTonal(onPressed: busy ? null : () => open('download'), icon: const Icon(Icons.download_rounded), tooltip: 'Enregistrer dans Download'),
          ]),
        ),
      ),
      body: Stack(children: [
        ListView(padding: const EdgeInsets.only(bottom: 38), children: [
          _BookHero(book: book),
          Transform.translate(
            offset: const Offset(0, -22),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
              decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(25), boxShadow: const [BoxShadow(color: Color(0x16000000), blurRadius: 20, offset: Offset(0, 8))]),
              child: Column(children: [
                Text(book.title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 7),
                Text(book.author, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 18),
                Row(children: [
                  _Stat(icon: Icons.star_rounded, value: averageRating > 0 ? averageRating.toStringAsFixed(1) : '—', label: 'Note', color: const Color(0xFFF4B740)),
                  _Stat(icon: Icons.visibility_outlined, value: _compact(book.views), label: 'Lectures'),
                  _Stat(icon: Icons.reviews_outlined, value: '${reviews.length}', label: 'Avis'),
                  _Stat(icon: Icons.download_outlined, value: _compact(book.downloads), label: 'Téléch.'),
                ]),
                const SizedBox(height: 18),
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _Action(icon: favorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, label: favorite ? 'Favori' : 'Ajouter', active: favorite, onTap: () => widget.state.toggleFavorite(book.id)),
                  _Action(icon: later ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, label: 'À lire', active: later, onTap: () => widget.state.toggleLater(book.id)),
                  _Action(icon: Icons.share_outlined, label: 'Partager', onTap: () => SharePlus.instance.share(ShareParams(text: '${book.title}\nhttps://fasobiblio.com/?doc=${book.id}'))),
                ]),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('À propos de cet ouvrage', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              Text(book.description.isEmpty ? 'La description de ce document sera bientôt disponible.' : book.description, style: const TextStyle(height: 1.6)),
              const SizedBox(height: 22),
              Container(padding: const EdgeInsets.symmetric(horizontal: 15), decoration: BoxDecoration(color: surface, border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)), borderRadius: BorderRadius.circular(17)), child: Column(children: [_Info('Rayon', categoryLabel(book.category)), _Info('Langue', book.language.toUpperCase()), _Info('Niveau', book.level.isEmpty ? 'Tous niveaux' : book.level), _Info('Année', book.year.isEmpty ? 'Non précisée' : book.year, last: true)])),
              const SizedBox(height: 28),
              Row(children: [const Expanded(child: Text('Avis des lecteurs', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900))), TextButton.icon(onPressed: _writeReview, icon: const Icon(Icons.rate_review_outlined, size: 18), label: const Text('Donner mon avis'))]),
              if (loadingReviews) const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Center(child: CircularProgressIndicator()))
              else if (reviews.isEmpty) const _NoReviews()
              else ...reviews.map((review) => _ReviewCard(review: review)),
            ]),
          ),
        ]),
        if (busy) Positioned.fill(child: ColoredBox(color: const Color(0x66000000), child: Center(child: Container(width: 245, padding: const EdgeInsets.all(23), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20)), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(value: progress == 0 ? null : progress), const SizedBox(height: 13), Text(progress == 0 ? 'Préparation du document…' : 'Téléchargement ${((progress ?? 0) * 100).round()} %', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))]))))),
      ]),
    );
  }

  static String _compact(int value) => value > 999 ? '${(value / 1000).toStringAsFixed(1)}k' : '$value';
}

class _BookHero extends StatelessWidget {
  const _BookHero({required this.book});
  final Book book;
  @override
  Widget build(BuildContext context) => Container(
    height: 335,
    decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0D2750), AppColors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight)),
    child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(17), child: book.image.isEmpty ? Container(width: 170, height: 245, color: AppColors.sky, child: const Icon(Icons.menu_book_rounded, size: 55, color: AppColors.blue)) : CachedNetworkImage(imageUrl: book.image, width: 170, height: 245, fit: BoxFit.cover, placeholder: (_, __) => Container(width: 170, height: 245, color: AppColors.sky), errorWidget: (_, __, ___) => Container(width: 170, height: 245, color: AppColors.sky, child: const Icon(Icons.menu_book_rounded, color: AppColors.blue))))),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value, required this.label, this.color = AppColors.blue});
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [Icon(icon, size: 19, color: color), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 9, color: AppColors.muted))]));
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, required this.onTap, this.active = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(30), child: Padding(padding: const EdgeInsets.all(7), child: Column(children: [CircleAvatar(backgroundColor: active ? AppColors.blue : AppColors.sky, foregroundColor: active ? Colors.white : AppColors.blue, child: Icon(icon, size: 20)), const SizedBox(height: 5), Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.muted))])));
}

class _Info extends StatelessWidget {
  const _Info(this.label, this.value, {this.last = false});
  final String label;
  final String value;
  final bool last;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(vertical: 13), decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: .45)))), child: Row(children: [Text(label, style: const TextStyle(color: AppColors.muted)), const Spacer(), Flexible(child: Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)))]));
}

class _NoReviews extends StatelessWidget {
  const _NoReviews();
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(18), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17)), child: const Column(children: [Icon(Icons.chat_bubble_outline_rounded, color: AppColors.muted), SizedBox(height: 8), Text('Aucun avis publié pour le moment.', style: TextStyle(color: AppColors.muted))]));
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final DocumentReview review;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(17), border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .45))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      CircleAvatar(backgroundColor: AppColors.sky, foregroundColor: AppColors.blue, child: Text(review.name.isEmpty ? 'L' : review.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(review.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900))), ...List.generate(5, (index) => Icon(index < review.stars ? Icons.star_rounded : Icons.star_border_rounded, size: 14, color: const Color(0xFFF4B740)))]), if (review.comment.isNotEmpty) ...[const SizedBox(height: 6), Text(review.comment, style: const TextStyle(height: 1.45))]])]),
    ]),
  );
}

class _ReviewDraft {
  const _ReviewDraft(this.stars, this.comment);
  final int stars;
  final String comment;
}

class _ReviewSheet extends StatefulWidget {
  const _ReviewSheet();
  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  final controller = TextEditingController();
  int stars = 5;
  @override
  void dispose() { controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Center(child: SizedBox(width: 42, child: Divider(thickness: 4))),
      const SizedBox(height: 12),
      Text('Votre avis', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 7),
      const Text('Il sera publié après validation par Fasobiblio.', style: TextStyle(color: AppColors.muted)),
      const SizedBox(height: 15),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (index) => IconButton(onPressed: () => setState(() => stars = index + 1), icon: Icon(index < stars ? Icons.star_rounded : Icons.star_border_rounded, color: const Color(0xFFF4B740), size: 32)))),
      const SizedBox(height: 8),
      TextField(controller: controller, minLines: 3, maxLines: 5, maxLength: 500, decoration: const InputDecoration(labelText: 'Votre commentaire', hintText: 'Ce que vous avez pensé du document…')),
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context, _ReviewDraft(stars, controller.text.trim())), icon: const Icon(Icons.send_rounded), label: const Text('Envoyer mon avis'))),
    ]),
  );
}
