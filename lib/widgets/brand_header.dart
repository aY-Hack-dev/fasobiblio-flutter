import 'package:flutter/material.dart';
import '../core/theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.compact = false});
  final bool compact;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final narrow = constraints.maxWidth < 350;
    final logoSize = narrow ? 40.0 : 46.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(narrow ? 14 : 20, compact ? 12 : 18, narrow ? 14 : 20, 14),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.asset('assets/branding/icon.png', width: logoSize, height: logoSize, fit: BoxFit.cover),
        ),
        SizedBox(width: narrow ? 8 : 11),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text.rich(
            const TextSpan(children: [
              TextSpan(text: 'FASO', style: TextStyle(color: AppColors.ink)),
              TextSpan(text: 'BIBLIO', style: TextStyle(color: AppColors.blue)),
            ]),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: narrow ? 17 : 19, fontWeight: FontWeight.w900, letterSpacing: narrow ? .3 : .6),
          ),
          const Text('Bibliothèque numérique', maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: AppColors.muted)),
        ])),
        SizedBox(width: narrow ? 6 : 10),
        CircleAvatar(
          radius: narrow ? 19 : 20,
          backgroundColor: AppColors.sky,
          foregroundColor: AppColors.blue,
          child: const Icon(Icons.notifications_none_rounded),
        ),
      ]),
    );
  });
}
