import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/app_feedback.dart';
import '../services/app_state.dart';

Future<void> showAuthSheet(BuildContext context, AppState state, {required bool signup}) async {
  final pseudo = TextEditingController(), password = TextEditingController(), phone = TextEditingController();
  String? error;
  var busy = false;
  var passwordVisible = false;

  String? validatePseudo(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Choisissez un nom d’utilisateur.';
    if (trimmed.length < 3) return 'Ajoutez encore ${3 - trimmed.length} caractère${3 - trimmed.length > 1 ? 's' : ''} au pseudo.';
    if (trimmed.length > 24) return 'Le pseudo ne peut pas dépasser 24 caractères.';
    final invalid = RegExp(r'[^A-Za-z0-9_.-]').firstMatch(trimmed);
    if (invalid != null) return 'Le caractère « ${invalid.group(0)} » n’est pas autorisé. Utilisez lettres, chiffres, point, tiret ou underscore.';
    return null;
  }
  String? validatePassword(String value) {
    if (value.isEmpty) return 'Saisissez votre mot de passe.';
    if (value.length < 8) return 'Mot de passe trop court : ${value.length}/8 caractères. Ajoutez encore ${8 - value.length}.';
    return null;
  }

  await showModalBottomSheet<void>(context: context,isScrollControlled: true,useSafeArea: true,backgroundColor: Colors.transparent,barrierColor: Colors.black.withValues(alpha: .52),builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) {
    Future<void> submit() async {
      final pseudoError=validatePseudo(pseudo.text); if(pseudoError!=null){setModalState(()=>error=pseudoError);return;}
      final passwordError=validatePassword(password.text); if(passwordError!=null){setModalState(()=>error=passwordError);return;}
      if(signup){final digits=phone.text.replaceAll(RegExp(r'\D'),'');if(!RegExp(r'^\d{8,10}$').hasMatch(digits)){setModalState(()=>error='Numéro invalide : saisissez 8 à 10 chiffres pour le téléphone de récupération.');return;}}
      setModalState((){busy=true;error=null;});
      try{signup?await state.signup(pseudo.text.trim(),password.text,phone.text):await state.login(pseudo.text.trim(),password.text);if(!sheetContext.mounted)return;await Future<void>.delayed(const Duration(milliseconds:350));if(sheetContext.mounted)Navigator.pop(sheetContext);if(context.mounted)showToast(context,signup?'Compte créé et synchronisé.':'Connexion réussie.',success:true);}catch(e){if(sheetContext.mounted)setModalState(()=>error=friendlyFailure(e,action:signup?'créer votre compte':'vous connecter'));}finally{if(sheetContext.mounted)setModalState(()=>busy=false);}
    }
    final dark=Theme.of(context).brightness==Brightness.dark;
    return SafeArea(top:false,child:Material(color:dark?const Color(0xFF111B2C):Colors.white,borderRadius:const BorderRadius.vertical(top:Radius.circular(30)),clipBehavior:Clip.antiAlias,child:SingleChildScrollView(padding:EdgeInsets.fromLTRB(22,10,22,MediaQuery.viewInsetsOf(context).bottom+24),child:Column(mainAxisSize:MainAxisSize.min,children:[
      Container(width:44,height:5,decoration:BoxDecoration(color:dark?const Color(0xFF43516A):const Color(0xFFD4DDEA),borderRadius:BorderRadius.circular(10))),const SizedBox(height:16),
      Row(children:[Container(width:46,height:46,decoration:BoxDecoration(color:AppColors.sky,borderRadius:BorderRadius.circular(15)),child:const Icon(AppIcons.account,color:AppColors.blue)),const SizedBox(width:12),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(signup?'Créer mon compte':'Se connecter',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:2),Text(signup?'Synchronisez vos achats, favoris et accès Premium.':'Retrouvez votre bibliothèque Fasobiblio.',style:const TextStyle(fontSize:11.5,color:AppColors.muted))])),IconButton(onPressed:busy?null:()=>Navigator.pop(sheetContext),icon:const Icon(AppIcons.close))]),
      const SizedBox(height:20),TextField(controller:pseudo,enabled:!busy,textInputAction:TextInputAction.next,autocorrect:false,onChanged:(_){if(error!=null)setModalState(()=>error=null);},decoration:const InputDecoration(labelText:'Nom d’utilisateur',hintText:'3 à 24 caractères',prefixIcon:Icon(AppIcons.user))),
      const SizedBox(height:12),TextField(controller:password,enabled:!busy,obscureText:!passwordVisible,onChanged:(_){if(error!=null)setModalState(()=>error=null);},decoration:InputDecoration(labelText:'Mot de passe',hintText:'8 caractères minimum',prefixIcon:const Icon(AppIcons.lock),suffixIcon:IconButton(onPressed:busy?null:()=>setModalState(()=>passwordVisible=!passwordVisible),tooltip:passwordVisible?'Masquer le mot de passe':'Afficher le mot de passe',icon:Icon(passwordVisible?Icons.visibility_off_outlined:Icons.visibility_outlined)))),
      if(signup)...[const SizedBox(height:12),TextField(controller:phone,enabled:!busy,keyboardType:TextInputType.phone,onChanged:(_){if(error!=null)setModalState(()=>error=null);},decoration:const InputDecoration(labelText:'Téléphone de récupération',hintText:'Ex : 70 12 34 56',prefixIcon:Icon(AppIcons.phone)))],
      AnimatedSwitcher(duration:const Duration(milliseconds:180),child:error==null?const SizedBox(height:8):Container(key:ValueKey(error),width:double.infinity,margin:const EdgeInsets.only(top:12),padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:const Color(0xFFFFF1F2),borderRadius:BorderRadius.circular(14),border:Border.all(color:const Color(0xFFFECACA))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.error_outline_rounded,color:Color(0xFFDC2626),size:20),const SizedBox(width:9),Expanded(child:Text(error!,style:const TextStyle(fontSize:11.5,height:1.4,color:Color(0xFFB91C1C),fontWeight:FontWeight.w700)))]))),
      const SizedBox(height:14),SizedBox(width:double.infinity,child:FilledButton(onPressed:busy?null:submit,child:AnimatedSwitcher(duration:const Duration(milliseconds:180),child:busy?const Row(key:ValueKey('busy'),mainAxisAlignment:MainAxisAlignment.center,children:[SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2.2,color:Colors.white)),SizedBox(width:10),Text('Veuillez patienter…')]):Text(key:const ValueKey('idle'),signup?'Créer le compte':'Connexion')))),
    ]))));
  }));
  pseudo.dispose();password.dispose();phone.dispose();
}
