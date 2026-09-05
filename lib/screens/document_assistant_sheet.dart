import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../services/app_state.dart';
import '../services/document_summary.dart';
import 'assistant_screen.dart';

class DocumentAssistantSheet extends StatefulWidget {
  const DocumentAssistantSheet({super.key,required this.path,required this.title,required this.id,required this.page,required this.state});
  final String path,title,id;
  final int page;
  final AppState state;
  @override State<DocumentAssistantSheet> createState()=>_DocumentAssistantSheetState();
}
class _DocumentAssistantSheetState extends State<DocumentAssistantSheet>{
  int points=5;bool busy=false;String? explanation,error;
  String get key=>'${widget.state.assistantAccountKey}.${widget.id}';
  DocumentSummary get job=>DocumentSummary.forDocument(key,points);
  @override void initState(){super.initState();job.restore();}
  Future<void> explain({bool question=false})async{
    setState((){busy=true;error=null;});PdfDocument? document;
    try{
      document=await PdfDocument.openFile(widget.path);
      final page=widget.page.clamp(1,document.pages.length);
      final text=(await document.pages[page-1].loadText())?.fullText??'';
      if(text.trim().isEmpty)throw Exception('Cette page ne contient pas de texte extractible.');
      final excerpt='Page $page :\n${text.length>27000?text.substring(0,27000):text}';
      if(!mounted)return;
      if(question){await Navigator.push(context,MaterialPageRoute(builder:(_)=>AssistantScreen(state:widget.state,documentTitle:widget.title,documentId:widget.id,documentContext:excerpt)));}
      else {final answer=await widget.state.api.assistant('Explique cette page simplement.',documentContext:excerpt,task:'explain');if(mounted)setState(()=>explanation=answer);}
    }catch(e){if(mounted)setState(()=>error='$e');}finally{await document?.dispose();if(mounted)setState(()=>busy=false);}
  }
  @override Widget build(BuildContext context)=>SafeArea(child:Padding(padding:const EdgeInsets.all(20),child:AnimatedBuilder(animation:job,builder:(context,_)=>ListView(children:[
    Row(children:[Expanded(child:Text('Assistant du document',style:Theme.of(context).textTheme.titleLarge)),IconButton(onPressed:()=>Navigator.pop(context),icon:const Icon(Icons.close))]),
    Text(widget.title,style:Theme.of(context).textTheme.titleMedium),const SizedBox(height:18),
    SegmentedButton<int>(segments:const[ButtonSegment(value:5,label:Text('5 points')),ButtonSegment(value:10,label:Text('10 points'))],selected:{points},onSelectionChanged:(v){setState(()=>points=v.first);job.restore();}),
    const SizedBox(height:12),
    FilledButton.icon(onPressed:job.running?null:()=>job.run(widget.path,widget.state.api,points),icon:const Icon(Icons.auto_awesome),label:Text(job.result!=null?'Résumé enregistré':job.page>0?'Reprendre le résumé':'Résumer tout le document')),
    if(job.running)...[const SizedBox(height:10),LinearProgressIndicator(value:job.total==0?null:job.page/job.total),Text('${job.page}/${job.total} pages parcourues'),TextButton(onPressed:job.pause,child:const Text('Mettre en pause'))],
    if(job.error!=null)Text(job.error!,style:TextStyle(color:Theme.of(context).colorScheme.error)),
    if(job.result!=null)AssistantMessageBody(text:job.result!),
    const Divider(height:28),
    OutlinedButton.icon(onPressed:busy?null:()=>explain(),icon:const Icon(Icons.description_outlined),label:Text('Expliquer la page ${widget.page}')),
    OutlinedButton.icon(onPressed:busy?null:()=>explain(question:true),icon:const Icon(Icons.chat_bubble_outline),label:const Text('Poser une question')),
    if(busy)const LinearProgressIndicator(),if(error!=null)Text(error!),if(explanation!=null)AssistantMessageBody(text:explanation!),
  ]))));
}
