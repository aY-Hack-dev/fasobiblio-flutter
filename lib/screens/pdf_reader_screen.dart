import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../core/theme.dart';
import '../services/local_store.dart';
import '../widgets/app_scope.dart';

import 'document_assistant_sheet.dart';

class PdfReaderScreen extends StatefulWidget {
  const PdfReaderScreen({super.key, required this.path, required this.title, this.documentId});

  final String path;
  final String title;
  final String? documentId;

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}
class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final viewer = PdfViewerController();
  late final Future<int> savedPage = _loadPage();
  int currentPage = 1;

  String get path => widget.path;
  String get title => widget.title;
  String get pageKey => 'reader.page.${widget.documentId ?? path.split('/').last}';
  Future<int> _loadPage() async {
    try { final value = await LocalStore().loadJson(pageKey) ?? await LocalStore().loadJson('reader.page.${path.split('/').last}');
      currentPage = value is int && value > 0 ? value : 1;
    } catch (_) { currentPage=1; }
    return currentPage;
  }
  Future<void> documentAssistant() async {
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,useSafeArea:true,
      builder:(_)=>SizedBox(height:MediaQuery.sizeOf(context).height*.88,child:DocumentAssistantSheet(path:path,title:title,id:widget.documentId??path.split('/').last,page:currentPage,state:AppScope.of(context))));
  }
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0B1630),
        appBar: AppBar(
          toolbarHeight: 72,
          actions: [IconButton(tooltip: 'Assistant du document', onPressed: documentAssistant, icon: const Icon(AppIcons.sparkles))],
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
                    const Text('LECTURE FASOBIBLIO', style: TextStyle(fontSize:12, letterSpacing: 1.1, fontWeight: FontWeight.w900, color: Color(0xFF87A9ED))),
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
                  child: FutureBuilder<int>(future: savedPage, builder: (context, snapshot) => !snapshot.hasData ? const Center(child: CircularProgressIndicator()) : PdfViewer.file(path, controller: viewer, initialPageNumber: snapshot.data!, params: PdfViewerParams(onPageChanged: (page) { if (page != null) { currentPage = page; LocalStore().saveJson(pageKey, page).catchError((_) {}); } }))),
                ),
              ),
            ),
          ),
        ),
      );
}
