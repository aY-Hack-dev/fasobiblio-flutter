import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

enum InformationKind { about, terms, privacy, legal, downloads }

class InformationScreen extends StatefulWidget {
  const InformationScreen({super.key, required this.kind, required this.state});
  final InformationKind kind;
  final AppState state;

  @override
  State<InformationScreen> createState() => _InformationScreenState();
}

class _InformationScreenState extends State<InformationScreen> {
  List<(String, String)> sections = const [];
  bool loading = true;

  String get title => switch (widget.kind) {
    InformationKind.about => 'À propos de Fasobiblio',
    InformationKind.terms => 'Conditions d’utilisation',
    InformationKind.privacy => 'Politique de confidentialité',
    InformationKind.legal => 'Mentions légales',
    InformationKind.downloads => 'Lecture et téléchargements',
  };

  String? get firebasePath => switch (widget.kind) {
    InformationKind.about => 'settings/about',
    InformationKind.terms => 'settings/cgu',
    InformationKind.privacy => 'settings/privacy',
    InformationKind.legal => 'settings/mentionsLegales',
    InformationKind.downloads => null,
  };

  String get cacheKey => 'fasobiblio.flutter.${firebasePath?.replaceAll('/', '.') ?? 'downloads'}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.kind == InformationKind.downloads) {
      setState(() {
        sections = const [
          ('Lecture intégrée', 'Quand vous ouvrez un PDF, il est conservé dans l’espace privé de l’application et reste lisible hors connexion.'),
          ('Dossier public', 'Le bouton Télécharger crée une copie dans Download/Fasobiblio. Vous pouvez ensuite la retrouver avec l’application Fichiers de votre téléphone.'),
          ('Mises à jour', 'Une copie déjà enregistrée peut rester sur le téléphone même si une nouvelle version du document est publiée en ligne.'),
        ];
        loading = false;
      });
      return;
    }

    final cached = await widget.state.store.loadJson(cacheKey);
    final cachedSections = _parseSections(cached);
    if (mounted && cachedSections.isNotEmpty) {
      setState(() {
        sections = cachedSections;
        loading = false;
      });
    }

    if (!widget.state.offline && firebasePath != null) {
      try {
        final remote = await widget.state.api.setting(firebasePath!);
        final remoteSections = _parseSections(remote);
        if (remoteSections.isNotEmpty) {
          await widget.state.store.saveJson(cacheKey, remote);
          if (mounted) setState(() => sections = remoteSections);
        }
      } catch (_) {
        // La dernière version enregistrée reste affichée sans exposer d'erreur technique.
      }
    }
    if (mounted) setState(() => loading = false);
  }

  List<(String, String)> _parseSections(dynamic value) {
    if (value is! Map) return const [];
    final raw = value['sections'];
    final items = raw is List ? raw : raw is Map ? raw.values.toList() : const [];
    return items.whereType<Map>().map((item) {
      final sectionTitle = _localized(item['title']);
      final content = _localized(item['content']);
      return (sectionTitle, content);
    }).where((item) => item.$1.isNotEmpty || item.$2.isNotEmpty).toList();
  }

  String _localized(dynamic value) {
    if (value is String) return value.trim();
    if (value is Map) {
      final french = value['fr'];
      if (french is String && french.trim().isNotEmpty) return french.trim();
      for (final candidate in value.values) {
        if (candidate is String && candidate.trim().isNotEmpty) return candidate.trim();
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : sections.isEmpty
            ? const _UnavailableContent()
            : ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 38),
                children: [
                  if (widget.kind == InformationKind.about) ...[
                    Container(
                      height: 155,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.blueDeep, AppColors.blue]),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Image.asset('assets/branding/logo-full.jpg', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 18),
                  ],
                  ...sections.map((section) => Container(
                    margin: const EdgeInsets.only(bottom: 13),
                    padding: const EdgeInsets.all(19),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: .5)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Color(0x0B0B3B78), blurRadius: 16, offset: Offset(0, 7))],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (section.$1.isNotEmpty) Text(section.$1, style: AppTypography.display(size: 18, weight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
                      if (section.$1.isNotEmpty && section.$2.isNotEmpty) const SizedBox(height: 9),
                      if (section.$2.isNotEmpty) Text(section.$2, style: const TextStyle(height: 1.62, color: AppColors.muted)),
                    ]),
                  )),
                ],
              ),
  );
}

class _UnavailableContent extends StatelessWidget {
  const _UnavailableContent();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(34),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircleAvatar(radius: 30, backgroundColor: AppColors.sky, foregroundColor: AppColors.blue, child: Icon(AppIcons.cloudSync)),
        const SizedBox(height: 15),
        Text('Contenu en cours de synchronisation', textAlign: TextAlign.center, style: AppTypography.display(size: 19, weight: FontWeight.w900, color: Theme.of(context).colorScheme.onSurface)),
        const SizedBox(height: 8),
        const Text('Cette rubrique apparaîtra automatiquement dès que les informations du site seront disponibles.', textAlign: TextAlign.center, style: TextStyle(height: 1.5, color: AppColors.muted)),
      ]),
    ),
  );
}
