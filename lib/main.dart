import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'screens/app_shell.dart';
import 'services/app_state.dart';
import 'services/fasobiblio_api.dart';
import 'services/local_store.dart';
import 'widgets/app_scope.dart';

void main(){WidgetsFlutterBinding.ensureInitialized();final state=AppState(FasobiblioApi(),LocalStore());runApp(FasobiblioApp(state:state));state.load();state.startConnectivityMonitoring();}
class FasobiblioApp extends StatelessWidget{const FasobiblioApp({super.key,required this.state});final AppState state;@override Widget build(BuildContext context)=>AppScope(state:state,child:AnimatedBuilder(animation:state,builder:(_,__)=>MaterialApp(title:'Fasobiblio',debugShowCheckedModeBanner:false,theme:buildTheme(),darkTheme:buildTheme(brightness:Brightness.dark),themeMode:switch(state.themeMode){'dark'=>ThemeMode.dark,'light'=>ThemeMode.light,_=>ThemeMode.system},home:StartupScreen(state:state))));}
