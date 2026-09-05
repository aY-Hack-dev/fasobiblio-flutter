import 'package:flutter/foundation.dart';
import 'package:pdfrx/pdfrx.dart';
import 'fasobiblio_api.dart';
import 'local_store.dart';

class DocumentSummary extends ChangeNotifier {
  DocumentSummary._(this.key);
  static final _jobs = <String,DocumentSummary>{};
  static DocumentSummary forDocument(String id, int points) => _jobs.putIfAbsent('$id.$points',()=>DocumentSummary._('$id.$points'));
  final String key;
  bool running=false, paused=false, loaded=false;
  int page=0,total=0,chunk=0;
  String? result,error;
  List<String> notes=[],missing=[];
  String get storageKey=>'document.summary.v1.$key';
  Future<void> restore() async {
    if(loaded)return;loaded=true;
    final data=await LocalStore().loadJson(storageKey);
    if(data is Map){page=data['page']??0;total=data['total']??0;chunk=data['chunk']??0;result=data['result'];notes=List<String>.from(data['notes']??[]);missing=List<String>.from(data['missing']??[]);}
    notifyListeners();
  }
  Future<void> save()=>LocalStore().saveJson(storageKey,{'page':page,'total':total,'chunk':chunk,'result':result,'notes':notes,'missing':missing});
  void pause(){paused=true;notifyListeners();}
  Future<String> request(FasobiblioApi api,String context,{String task='section',int points=5}) async {
    // Below the shared service limit even when responses are immediate.
    await Future<void>.delayed(const Duration(milliseconds:2200));
    return api.assistant(task=='summary'?'Produis le résumé final.':'Résume ces pages fidèlement avec leurs références.',documentContext:context,task:task,points:points);
  }
  Future<void> run(String path,FasobiblioApi api,int points) async {
    if(running)return;
    await restore();if(result!=null)return;
    running=true;paused=false;error=null;notifyListeners();
    PdfDocument? document;
    try {
      document=await PdfDocument.openFile(path);total=document.pages.length;
      while(page<total && !paused){
        final text=(await document.pages[page].loadText())?.fullText??'';
        if(text.trim().isEmpty){missing.add('${page+1}');page++;chunk=0;await save();notifyListeners();continue;}
        final parts=<String>[];
        for(var i=0;i<text.length;i+=14000){parts.add(text.substring(i,(i+14000).clamp(0,text.length)));}
        while(chunk<parts.length && !paused){
          notes.add(await request(api,'Page ${page+1}, partie ${chunk+1}/${parts.length}:\n${parts[chunk]}'));
          chunk++;await save();notifyListeners();
        }
        if(!paused){page++;chunk=0;await save();notifyListeners();}
      }
      if(paused)return;
      if(notes.isEmpty)throw Exception('Ce PDF est scanné ou ne contient pas de texte extractible. Une reconnaissance du texte est nécessaire.');
      // Hierarchical reduction covers every extracted section, including long books.
      var reduced=List<String>.from(notes);
      while(reduced.join('\n\n').length>22000 && !paused){
        final next=<String>[];var batch='';
        for(final note in reduced){
          if(batch.length+note.length>18000 && batch.isNotEmpty){next.add(await request(api,batch));batch='';if(paused)break;}
          batch+='$note\n\n';
        }
        if(paused)return;
        if(batch.isNotEmpty)next.add(await request(api,batch));
        if(next.join().length>=reduced.join().length)throw Exception('Synthèse trop longue. Réessayez pour poursuivre.');
        reduced=next;
      }
      if(paused)return;
      result=await request(api,'Couverture : $total pages parcourues. Pages sans texte extractible : ${missing.isEmpty?'aucune':missing.join(', ')}.\n${reduced.join('\n\n')}',task:'summary',points:points);
      if(missing.isNotEmpty)result='**Résumé partiel : ${missing.length} page(s) sans texte extractible.**\n\n$result';
      await save();
    } catch(e){error='$e';} finally{await document?.dispose();running=false;notifyListeners();}
  }
}
