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
      memCacheWidth: 500,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 240),
      fadeOutDuration: const Duration(milliseconds: 120),
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
            gradient: LinearGradient(
              colors: [Color(0xFFF5F7FB), Color(0xFFE9EEF7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -18,
                top: -18,
                child: Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .045), shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 22,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: .10), borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Positioned(
                left: 14,
                right: 30,
                top: 34,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: .07), borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Center(
                child: Container(
                  width: 44,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDCE4F0)),
                  ),
                  child: const Icon(AppIcons.bookOpen, size: 21, color: AppColors.blueDeep),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 18,
                child: Row(
                  children: [
                    Expanded(child: Container(height: 3, decoration: BoxDecoration(color: AppColors.blue.withValues(alpha: .12), borderRadius: BorderRadius.circular(99)))),
                    const SizedBox(width: 7),
                    Container(width: 20, height: 3, decoration: BoxDecoration(color: AppColors.ink.withValues(alpha: .08), borderRadius: BorderRadius.circular(99))),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
