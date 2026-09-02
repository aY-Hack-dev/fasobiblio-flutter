import 'package:flutter/material.dart';
import '../core/theme.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction});
  final String title; final String? action; final VoidCallback? onAction;
  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 25, 16, 11),
    child: Column(children: [
      Row(children: [Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)), if (action != null) TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.blue)))]),
      const SizedBox(height: 7),
      Container(height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.blue, AppColors.line, Colors.transparent], stops: [0, .22, 1]))),
    ]),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.icon = AppIcons.bookOpen});
  final String title; final String message; final IconData icon;
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(42), child: Column(children: [Container(width: 72, height: 72, decoration: const BoxDecoration(color: AppColors.sky, shape: BoxShape.circle), child: Icon(icon, color: AppColors.blue, size: 34)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: 7), Text(message, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall)]));
}
