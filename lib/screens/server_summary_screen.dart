import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_feedback.dart';
import '../services/app_state.dart';
import 'assistant_screen.dart';

class ServerSummaryScreen extends StatefulWidget {
  const ServerSummaryScreen({
    super.key,
    required this.state,
    this.docId,
    this.title,
    this.points = 5,
    this.jobId,
  });
  final AppState state;
  final String? docId, title, jobId;
  final int points;
  @override
  State<ServerSummaryScreen> createState() => _ServerSummaryScreenState();
}

class _ServerSummaryScreenState extends State<ServerSummaryScreen> {
  Map<String, dynamic>? job;
  String? error;
  Timer? timer;
  bool busy = false;
  String? id;
  String get cacheKey => 'summary.result.${widget.state.session?.uid}.$id';
  @override
  void initState() {
    super.initState();
    id = widget.jobId;
    refresh();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> refresh() async {
    if (busy) return;
    timer?.cancel();
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (id == null) {
        final value = await widget.state.api.authenticated(
          '/api/summary-jobs',
          method: 'POST',
          body: {'docId': widget.docId ?? job?['docId'], 'points': job?['points'] ?? widget.points},
        );
        job = Map<String, dynamic>.from(value);
        id = '${job!['id']}';
      } else {
        final value = await widget.state.api.authenticated(
          '/api/summary-jobs/$id',
        );
        job = Map<String, dynamic>.from(value);
      }
      if (job?['status'] == 'ready') {
        await widget.state.store.saveJson(cacheKey, job!);
      }
      if (mounted && ['queued', 'running'].contains(job?['status'])) {
        timer = Timer(const Duration(seconds: 5), refresh);
      }
    } catch (_) {
      // Only a result already authorized and saved for this account is shown offline.
      if (id != null) {
        final saved = await widget.state.store.loadJson(cacheKey);
        if (saved is Map) job = Map<String, dynamic>.from(saved);
      }
      error = id == null
          ? 'Le traitement serveur n’est pas disponible pour le moment. Réessayez plus tard.'
          : 'Impossible d’actualiser le suivi. Le serveur peut continuer le traitement ; revenez vérifier plus tard.';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = '${job?['status'] ?? ''}';
    final total = (job?['total'] as num?)?.toInt() ?? 0;
    final page = (job?['page'] as num?)?.toInt() ?? 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Résumé du livre')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            '${job?['title'] ?? widget.title ?? 'Document'}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          if (status == 'ready')
            AssistantMessageBody(text: '${job?['result'] ?? ''}')
          else if (status == 'queued' || status == 'running') ...[
            const Icon(Icons.auto_stories, size: 56),
            const SizedBox(height: 16),
            Text(
              status == 'queued'
                  ? 'Votre résumé est dans la file d’attente.'
                  : 'Préparation du résumé…',
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: total > 0 ? (page / total).clamp(0.0, 1.0) : null,
            ),
            const SizedBox(height: 8),
            if (total > 0) Text('$page / $total pages traitées'),
            const SizedBox(height: 20),
            const Text(
              'Vous pouvez quitter cet écran ou fermer l’application. Retrouvez le résultat dans Profil → Mes résumés.',
            ),
          ],
          if (busy)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (error != null) Text(error!),
          if (status == 'failed') ...[
            Text('${job?['error'] ?? 'Le traitement a été interrompu.'}'),
            TextButton(
              onPressed: busy
                  ? null
                  : () {
                      id = null;
                      refresh();
                    },
              child: const Text('Reprendre le traitement'),
            ),
          ],
          if (error != null)
            TextButton(
              onPressed: busy ? null : refresh,
              child: const Text('Réessayer'),
            ),
        ],
      ),
    );
  }
}

class SummaryLibraryScreen extends StatefulWidget {
  const SummaryLibraryScreen({super.key, required this.state});
  final AppState state;
  @override
  State<SummaryLibraryScreen> createState() => _SummaryLibraryScreenState();
}

class _SummaryLibraryScreenState extends State<SummaryLibraryScreen> {
  List<Map<String, dynamic>> jobs = [];
  bool busy = true;
  String? error;
  String get key => 'summary.list.${widget.state.session?.uid}';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final data = await widget.state.api.authenticated('/api/summary-jobs');
      jobs = (data['jobs'] as List)
          .whereType<Map>()
          .map((x) => Map<String, dynamic>.from(x))
          .toList();
      await widget.state.store.saveJson(key, jobs);
      error = null;
    } catch (e) {
      final cached = await widget.state.store.loadJson(key);
      if (cached is List) {
        jobs = cached
            .whereType<Map>()
            .map((x) => Map<String, dynamic>.from(x))
            .toList();
      }
      error = friendlyFailure(e, action: 'actualiser vos résumés');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Mes résumés'),
      actions: [
        IconButton(
          onPressed: load,
          icon: const Icon(Icons.refresh),
          tooltip: 'Actualiser',
        ),
      ],
    ),
    body: busy
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (error != null)
                Padding(padding: const EdgeInsets.all(16), child: Text(error!)),
              if (jobs.isEmpty && error == null)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Lancez un résumé depuis l’assistant d’un document. Vous le retrouverez ici.',
                  ),
                ),
              for (final job in jobs)
                ListTile(
                  leading: Icon(
                    job['status'] == 'ready'
                        ? Icons.task_alt
                        : job['status'] == 'failed'
                        ? Icons.error_outline
                        : Icons.hourglass_top,
                  ),
                  title: Text('${job['title']}'),
                  subtitle: Text(
                    '${job['points']} points · ${switch (job['status']) {
                      'ready' => 'Prêt',
                      'failed' => 'À reprendre',
                      'running' => 'En préparation',
                      _ => 'En attente',
                    }}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ServerSummaryScreen(
                          state: widget.state,
                          jobId: '${job['id']}',
                          docId: '${job['docId']}',
                          title: '${job['title']}',
                          points: (job['points'] as num).toInt(),
                        ),
                      ),
                    );
                    if (mounted) load();
                  },
                ),
            ],
          ),
  );
}
