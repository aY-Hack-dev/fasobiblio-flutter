import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../core/theme.dart';
import '../services/document_service.dart';
import '../core/app_feedback.dart';
import 'pdf_reader_screen.dart';

class OfflineDocumentsScreen extends StatefulWidget {
  const OfflineDocumentsScreen({super.key});

  @override
  State<OfflineDocumentsScreen> createState() => _OfflineDocumentsScreenState();
}

class _OfflineDocumentsScreenState extends State<OfflineDocumentsScreen> {
  List<File> files = const [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final root = await getApplicationDocumentsDirectory();
    final directory = Directory('${root.path}/documents');
    final found = <File>[];
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.pdf') && !entity.path.endsWith('.part')) {
          try {
            if (await entity.length() > 0) found.add(entity);
          } catch (_) {}
        }
      }
    }
    found.sort((a, b) {
      try { return b.lastModifiedSync().compareTo(a.lastModifiedSync()); } catch (_) { return 0; }
    });
    if (mounted) setState(() { files = found; loading = false; });
  }

  String _title(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    return name.replaceFirst(RegExp(r'\.pdf$', caseSensitive: false), '');
  }

  String _size(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).ceil()} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Documents hors connexion')),
    body: Column(children: [ValueListenableBuilder<List<DownloadTask>>(valueListenable: DocumentService.tasks, builder: (context, tasks, _) => Column(children: tasks.where((t) => t.running || t.error != null).map((task) => ListTile(title: Text(task.key, maxLines: 1, overflow: TextOverflow.ellipsis), subtitle: task.running ? LinearProgressIndicator(value: task.progress) : Text(task.error!), trailing: task.running ? null : IconButton(tooltip: 'Relancer', icon: const Icon(Icons.refresh), onPressed: () async { try { await DocumentService().ensureLocal(task.url, task.key); await _load(); } catch (e) { if (context.mounted) showToast(context, 'Relance impossible. Ouvrez à nouveau la fiche du document.'); } }))).toList())), Expanded(child: loading
        ? const Center(child: CircularProgressIndicator())
        : files.isEmpty
            ? const _EmptyOffline()
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 34),
                  itemCount: files.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final file = files[index];
                    final stat = file.statSync();
                    return Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(19),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(19),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PdfReaderScreen(path: file.path, title: _title(file)))),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(children: [
                            Container(width: 52, height: 64, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blueDeep, AppColors.blue]), borderRadius: BorderRadius.circular(14)), child: const Icon(AppIcons.bookOpen, color: Colors.white)),
                            const SizedBox(width: 13),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(_title(file), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                              const SizedBox(height: 6),
                              Text('${_size(stat.size)} • disponible hors connexion', style: const TextStyle(fontSize:12, color: AppColors.muted)),
                            ])),
                            IconButton(tooltip: 'Supprimer la copie hors connexion', icon: const Icon(Icons.delete_outline), onPressed: () async {
                              final yes = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Supprimer ce téléchargement ?'), content: const Text('La copie locale sera supprimée. Vous pourrez télécharger à nouveau le document.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')), TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer'))]));
                              if (yes == true) { try { await file.delete(); await _load(); } catch (e) { if (context.mounted) showToast(context, 'Suppression impossible.'); } }
                            }),
                          ]),
                        ),
                      ),
                    );
                  },
                ),
              ),
    )]),
  );
}

class _EmptyOffline extends StatelessWidget {
  const _EmptyOffline();
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.sky, borderRadius: BorderRadius.circular(24)), child: const Icon(AppIcons.download, color: AppColors.blue, size: 32)),
        const SizedBox(height: 16),
        Text('Aucun document enregistré', textAlign: TextAlign.center, style: AppTypography.display(size: 20, weight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        const Text('Les PDF que vous ouvrez dans Fasobiblio apparaîtront ici et resteront lisibles sans connexion.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.muted)),
      ]),
    ),
  );
}
