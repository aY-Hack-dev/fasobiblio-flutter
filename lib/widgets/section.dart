import 'package:flutter/material.dart';
import '../core/theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title; final String? action; final VoidCallback? onAction;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 26, 16, 12),
    child: Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.blue)))]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = Icons.auto_stories_outlined});
  final String title; final String message; final IconData icon;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(42), child: Column(children: [Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle), child: Icon(icon, color: AppColors.blue, size: 34)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 7), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]));
}
