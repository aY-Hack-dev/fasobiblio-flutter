import 'package:flutter/material.dart';
import '../core/theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, compact ? 12 : 18, 20, 14),
    child: Row(children: [
      ClipRRect(borderRadius: BorderRadius.circular(13), child: Image.asset('assets/branding/icon.png', width: 44, height: 44)),
      const SizedBox(width: 11),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text.rich(TextSpan(children: [TextSpan(text: 'FASO', style: TextStyle(color: AppColors.ink)), TextSpan(text: 'BIBLIO', style: TextStyle(color: AppColors.blue))]), style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: .6)),
        Text('Bibliothèque numérique', style: TextStyle(fontSize: 11, color: AppColors.muted)),
      ])),
      CircleAvatar(backgroundColor: AppColors.sky, foregroundColor: AppColors.blue, child: Icon(Icons.notifications_none_rounded)),
    ]),
  );
}
