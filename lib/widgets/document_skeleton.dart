import 'package:flutter/material.dart';
import '../services/app_state.dart';

/// Only document content is pending; surrounding navigation remains interactive.
class DocumentSkeleton extends StatelessWidget {
  const DocumentSkeleton({super.key, required this.state});
  final AppState state;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Widget bone(double height) => Container(height: height,
      decoration: BoxDecoration(color: colors.onSurface.withValues(alpha: .08), borderRadius: BorderRadius.circular(8)));
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      if (state.offline) Row(children: [
        const Expanded(child: Text('Documents en attente de connexion.', style: TextStyle(fontSize: 12))),
        TextButton(onPressed: state.refreshing ? null : () => state.load(refresh: true), child: const Text('Réessayer')),
      ]),
      Semantics(label: 'Chargement des documents', child: Row(children: List.generate(2, (i) => Expanded(
        child: Container(margin: EdgeInsets.only(right: i == 0 ? 12 : 0), padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: colors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.outlineVariant)),
          child: Column(children: [bone(156), const SizedBox(height: 12), bone(14), const SizedBox(height: 8), bone(10)])),
      )))),
    ]));
  }
}
