import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/app_feedback.dart';
import '../core/theme.dart';
import '../services/app_state.dart';

class AssistantScreen extends StatefulWidget{const AssistantScreen({super.key,required this.state,this.documentContext,this.documentTitle,this.documentId});final AppState state;final String? documentContext,documentTitle,documentId;@override State<AssistantScreen> createState()=>_AssistantScreenState();}
class _ChatMessage{const _ChatMessage(this.text,{required this.fromUser});final String text;final bool fromUser;Map<String,dynamic> toJson()=>{'text':text,'fromUser':fromUser};}
class _AssistantScreenState extends State<AssistantScreen>{
 final controller=TextEditingController();final scrollController=ScrollController();final messages=<_ChatMessage>[];bool busy=false,restoring=true;
 String get memoryKey => '${widget.state.assistantAccountKey}.${widget.documentId ?? widget.documentTitle ?? 'general'}';
 @override void initState(){super.initState();_restore();}
 Future<void> _restore()async{try{var saved=await widget.state.store.loadAssistantMemory(memoryKey);if(saved.isEmpty && widget.documentTitle==null)saved=await widget.state.store.loadAssistantMemory(widget.state.assistantAccountKey);if(!mounted)return;setState((){messages.addAll(saved.map((e)=>_ChatMessage('${e['text']??''}',fromUser:e['fromUser']==true)).where((e)=>e.text.isNotEmpty));restoring=false;});_scrollDown();}catch(_){if(mounted)setState(()=>restoring=false);}}
 Future<void> _persist()=>widget.state.store.saveAssistantMemory(memoryKey,messages.map((e)=>e.toJson()).toList());
 @override void dispose(){controller.dispose();scrollController.dispose();super.dispose();}
 Future<void> ask()async{final question=controller.text.trim();if(question.isEmpty||busy)return;if(!requireInternet(context,widget.state))return;controller.clear();setState((){messages.add(_ChatMessage(question,fromUser:true));busy=true;if(messages.length>80)messages.removeRange(0,messages.length-80);});_scrollDown();try{await _persist();final answer=await widget.state.api.assistant(question, documentContext: widget.documentContext, history: messages.take(messages.length-1).map((m)=>{'role':m.fromUser?'user':'assistant','content':m.text}).toList());if(!mounted)return;setState(()=>messages.add(_ChatMessage(answer,fromUser:false)));await _persist();}catch(error){if(mounted)showToast(context,friendlyFailure(error,action:'obtenir une réponse de l’assistant'));}finally{if(mounted)setState(()=>busy=false);_scrollDown();}}
 void _scrollDown()=>WidgetsBinding.instance.addPostFrameCallback((_){if(scrollController.hasClients)scrollController.animateTo(scrollController.position.maxScrollExtent,duration:const Duration(milliseconds:260),curve:Curves.easeOut);});
 @override Widget build(BuildContext context){final surface=Theme.of(context).colorScheme.surface;return Scaffold(appBar:AppBar(titleSpacing:0,title:const Row(children:[CircleAvatar(backgroundColor:AppColors.blue,foregroundColor:Colors.white,child:Icon(AppIcons.bot,size:21)),SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Assistant Fasobiblio',style:TextStyle(fontSize:16,fontWeight:FontWeight.w900)),SizedBox(height:2),Row(children:[CircleAvatar(radius:4,backgroundColor:Color(0xFF22C55E)),SizedBox(width:5),Text('Assistant bibliothèque',style:TextStyle(fontSize:12,fontWeight:FontWeight.w500,color:AppColors.muted))])]))])),body:Column(children:[if(widget.documentTitle!=null)Padding(padding:const EdgeInsets.all(12),child:Text('Questions sur les pages ouvertes : ${widget.documentTitle}',style:const TextStyle(fontSize:12))),Expanded(child:restoring?const Center(child:CircularProgressIndicator()):messages.isEmpty?const _Welcome():ListView.builder(controller:scrollController,padding:const EdgeInsets.fromLTRB(16,18,16,18),itemCount:messages.length+(busy?1:0),itemBuilder:(context,index)=>index==messages.length?const _TypingBubble():_MessageBubble(message:messages[index]))),Container(color:surface,padding:EdgeInsets.fromLTRB(12,10,12,MediaQuery.paddingOf(context).bottom+10),child:Row(crossAxisAlignment:CrossAxisAlignment.end,children:[Expanded(child:TextField(controller:controller,minLines:1,maxLines:4,textInputAction:TextInputAction.newline,decoration:const InputDecoration(hintText:'Posez votre question…',contentPadding:EdgeInsets.symmetric(horizontal:16,vertical:12)))),const SizedBox(width:9),IconButton.filled(onPressed:busy?null:ask,icon:const Icon(AppIcons.send),tooltip:'Envoyer',style:IconButton.styleFrom(minimumSize:const Size(50,50)))]))]));}
}
class _Welcome extends StatelessWidget{const _Welcome();@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(28,48,28,20),children:[Center(child:Container(width:68,height:68,decoration:BoxDecoration(gradient:const LinearGradient(colors:[AppColors.ink,AppColors.blue]),borderRadius:BorderRadius.circular(20)),child:const Icon(AppIcons.bot,color:Colors.white,size:31))),const SizedBox(height:20),Text('Votre assistant de lecture',textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineMedium),const SizedBox(height:12),const Text('Je vous aide à trouver des documents dans le catalogue Fasobiblio, à choisir vos prochaines lectures et à comprendre le fonctionnement de la bibliothèque et de Premium. Décrivez simplement ce que vous cherchez.',textAlign:TextAlign.center,style:TextStyle(color:AppColors.muted,height:1.55,fontSize:13))]);}
class _MessageBubble extends StatelessWidget{const _MessageBubble({required this.message});final _ChatMessage message;
 @override Widget build(BuildContext context) => Align(
   alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
   child: Container(width: double.infinity,
     margin: EdgeInsets.only(bottom: 13, left: message.fromUser ? 32 : 0, right: message.fromUser ? 0 : 8),
     padding: const EdgeInsets.all(14),
     decoration: BoxDecoration(color: message.fromUser ? AppColors.blue : Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16)),
     child: message.fromUser ? Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5)) : AssistantMessageBody(text: message.text),
   ),
 );
}
class AssistantMessageBody extends StatelessWidget {
  const AssistantMessageBody({super.key, required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    final blocks = <({String text, bool table})>[];
    var lines = <String>[];
    var table = false;
    for (final line in text.split('\n')) {
      final next = line.trim().startsWith('|') && line.trim().endsWith('|');
      if (next != table && lines.isNotEmpty) { blocks.add((text: lines.join('\n'), table: table)); lines = []; }
      table = next; lines.add(line);
    }
    if (lines.isNotEmpty) blocks.add((text: lines.join('\n'), table: table));
    Widget markdown(String data) => MarkdownBody(data: data, selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: const TextStyle(fontFamily: 'Urbanist', fontSize: 14, height: 1.5),
        h1: const TextStyle(fontFamily: 'Urbanist', fontSize: 18, fontWeight: FontWeight.w700),
        h2: const TextStyle(fontFamily: 'Urbanist', fontSize: 17, fontWeight: FontWeight.w700),
        h3: const TextStyle(fontFamily: 'Urbanist', fontSize: 16, fontWeight: FontWeight.w700),
        tableColumnWidth: const FixedColumnWidth(160),
      ));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks.map((block) {
      if (!block.table) return markdown(block.text);
      final columns = block.text.split('\n').first.split('|').length - 2;
      return SingleChildScrollView(scrollDirection: Axis.horizontal,
        child: SizedBox(width: (columns * 160.0).clamp(320.0, 1600.0).toDouble(), child: markdown(block.text)));
    }).toList());
  }
}
class _TypingBubble extends StatelessWidget{const _TypingBubble();@override Widget build(BuildContext context)=>Align(alignment:Alignment.centerLeft,child:Container(margin:const EdgeInsets.only(bottom:13),padding:const EdgeInsets.symmetric(horizontal:18,vertical:14),decoration:BoxDecoration(color:Theme.of(context).colorScheme.surface,borderRadius:BorderRadius.circular(18)),child:const SizedBox(width:38,child:LinearProgressIndicator(minHeight:3))));}
