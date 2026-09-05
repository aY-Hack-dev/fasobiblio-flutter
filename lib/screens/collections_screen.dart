import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../core/app_feedback.dart';
import 'book_detail_screen.dart';

class CollectionsScreen extends StatefulWidget {
  const CollectionsScreen({super.key, required this.state});
  final AppState state;
  @override
  State<CollectionsScreen> createState() => _CollectionsScreenState();
}
class _CollectionsScreenState extends State<CollectionsScreen> {
  Map<String, List<String>> collections = {};
  bool loading = true;
  late final String storageKey = 'collections.${widget.state.assistantAccountKey}';
  @override
  void initState() { super.initState(); load(); }
  Future<void> load() async {
    try {
      final raw = await widget.state.store.loadJson(storageKey);
      if (raw is Map) collections = raw.map((k, v) => MapEntry('$k', v is List ? v.map((e) => '$e').toList() : <String>[]));
    } catch (e) { if (mounted) showToast(context, 'Impossible de charger les collections.'); }
    if (mounted) setState(() => loading = false);
  }
  Future<void> save() async {
    try { await widget.state.store.saveJson(storageKey, collections); }
    catch (e) { if (mounted) showToast(context, 'La collection n’a pas pu être enregistrée.'); }
  }
  Future<void> create() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(context: context, builder: (context) => AlertDialog(
      title: const Text('Nouvelle collection'),
      content: TextField(controller: controller, maxLength: 50, decoration: const InputDecoration(hintText: 'Ex. Mes cours')),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(onPressed: () { if (controller.text.trim().isNotEmpty) Navigator.pop(context, controller.text.trim()); }, child: const Text('Créer'))],
    ));
    controller.dispose();
    if (name == null || !mounted) return;
    if (collections.containsKey(name)) { showToast(context, 'Cette collection existe déjà.'); return; }
    setState(() => collections[name] = []);
    await save();
  }
  Future<void> edit(String name) async {
    final selected = collections[name]!.toSet();
    var query = '';
    final result = await showModalBottomSheet<bool>(
      context: context, isScrollControlled: true, useSafeArea: true,
      builder: (context) => StatefulBuilder(builder: (context, update) {
        final books = widget.state.books.where((b) => b.title.toLowerCase().contains(query.toLowerCase())).toList();
        return SizedBox(height: MediaQuery.sizeOf(context).height * .8, child: Column(children: [
          Padding(padding: const EdgeInsets.all(16), child: Text(name, style: Theme.of(context).textTheme.titleLarge)),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: TextField(
            decoration: const InputDecoration(hintText: 'Rechercher un document'),
            onChanged: (v) => update(() => query = v))),
          Expanded(child: ListView.builder(itemCount: books.length, itemBuilder: (_, i) => CheckboxListTile(
            title: Text(books[i].title, maxLines: 2, overflow: TextOverflow.ellipsis),
            value: selected.contains(books[i].id),
            onChanged: (v) => update(() { v == true ? selected.add(books[i].id) : selected.remove(books[i].id); }),
          ))),
          SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: FilledButton(
            onPressed: () => Navigator.pop(context, true), child: const Text('Enregistrer la sélection')))),
        ]));
      }),
    );
    if (result == true && mounted) { setState(() => collections[name] = selected.toList()); await save(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mes collections'), actions: [IconButton(tooltip: 'Créer une collection', onPressed: create, icon: const Icon(Icons.create_new_folder_outlined))]),
    body: loading ? const Center(child: CircularProgressIndicator()) : collections.isEmpty
      ? Center(child: FilledButton.icon(onPressed: create, icon: const Icon(Icons.add), label: const Text('Créer ma première collection')))
      : ListView(children: collections.entries.map((entry) => ExpansionTile(
          title: Text(entry.key), subtitle: Text('${entry.value.length} documents'),
          children: [
            Wrap(children: [
              TextButton.icon(onPressed: () => edit(entry.key), icon: const Icon(Icons.edit_outlined), label: const Text('Choisir les documents')),
              TextButton(onPressed: () async {
                final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
                  title: const Text('Supprimer cette collection ?'), content: const Text('Les documents seront conservés.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
                if (yes == true && mounted) { setState(() => collections.remove(entry.key)); await save(); }
              }, child: const Text('Supprimer')),
            ]),
            ...widget.state.books.where((b) => entry.value.contains(b.id)).map((b) => ListTile(
              title: Text(b.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BookDetailScreen(book: b, state: widget.state)))) ,
          ],
        )).toList()),
  );
}
