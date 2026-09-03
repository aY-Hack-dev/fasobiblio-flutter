import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class DocumentCover extends StatelessWidget {
  const DocumentCover({super.key, required this.imageUrl, this.width, this.height, this.fit = BoxFit.cover});
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = _DocumentPlaceholder(width: width, height: height);
    if (imageUrl.trim().isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 140),
      placeholder: (_, __) => placeholder,
      errorWidget: (_, __, ___) => placeholder,
    );
  }
}

class _DocumentPlaceholder extends StatelessWidget {
  const _DocumentPlaceholder({this.width, this.height});
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    height: height,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFF2F6FF), Color(0xFFE4EDFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: Stack(fit: StackFit.expand, children: [
        Positioned(right: -24, top: -20, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .06), shape: BoxShape.circle))),
        Positioned(left: -28, bottom: -38, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: AppColors.blueDeep.withValues(alpha: .05), shape: BoxShape.circle))),
        Center(
          child: Container(
            margin: const EdgeInsets.all(18),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .88),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFD6E2FB)),
              boxShadow: const [BoxShadow(color: Color(0x150B3FB9), blurRadius: 18, offset: Offset(0, 8))],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]), borderRadius: BorderRadius.circular(15)), child: const Icon(AppIcons.bookOpen, color: Colors.white, size: 24)),
              const SizedBox(height: 12),
              const Text('FASOBIBLIO', style: TextStyle(fontSize: 11, letterSpacing: .7, fontWeight: FontWeight.w900, color: AppColors.ink)),
              const SizedBox(height: 4),
              const Text('Couverture indisponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 9.5, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.muted)),
            ]),
          ),
        ),
      ]),
    ),
  );
}
