import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme.dart';

class PdfReaderScreen extends StatelessWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF20242C),
    appBar: AppBar(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
    body: PdfViewer.file(path),
  );
}
