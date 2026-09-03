import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme.dart';

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1630),
        appBar: AppBar(
          toolbarHeight: 72,
          backgroundColor: const Color(0xFF0B1630),
          foregroundColor: Colors.white,
          titleSpacing: 4,
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.blue, AppColors.blueDeep]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(AppIcons.bookOpen, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('LECTURE FASOBIBLIO', style: TextStyle(fontSize: 9, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF87A9ED))),
                    const SizedBox(height: 3),
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTypography.display(size: 15, weight: FontWeight.w800, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF0B1630), Color(0xFF111C35)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: DecoratedBox(
                  decoration: const BoxDecoration(color: Color(0xFF20242C)),
                  child: PdfViewer.file(path),
                ),
              ),
            ),
          ),
        ),
      );
}
