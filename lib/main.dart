import 'services/push_service.dart';
import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/app_shell.dart';
import 'services/app_state.dart';
import 'services/fasobiblio_api.dart';
import 'services/local_store.dart';
import 'widgets/app_scope.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();PaintingBinding.instance.imageCache.maximumSizeBytes=48*1024*1024;PaintingBinding.instance.imageCache.maximumSize=100;final state=AppState(FasobiblioApi(),LocalStore());final navigator=GlobalKey<NavigatorState>();runApp(FasobiblioApp(state:state,navigatorKey:navigator));PushService.instance.initialize(state,navigator);state.load();state.startConnectivityMonitoring();}
class FasobiblioApp extends StatelessWidget{const FasobiblioApp({super.key,required this.state,this.navigatorKey});final AppState state;final GlobalKey<NavigatorState>? navigatorKey;@override Widget build(BuildContext context)=>AppScope(state:state,child:AnimatedBuilder(animation:state,builder:(_,__)=>MaterialApp(navigatorKey:navigatorKey,title:'Fasobiblio',debugShowCheckedModeBanner:false,theme:buildTheme(),darkTheme:buildTheme(brightness:Brightness.dark),themeMode:switch(state.themeMode){'dark'=>ThemeMode.dark,'light'=>ThemeMode.light,_=>ThemeMode.system},home:StartupScreen(state:state))));}
