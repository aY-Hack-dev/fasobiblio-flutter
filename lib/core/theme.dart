import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF101828);
  static const navy = Color(0xFF102A43);
  static const blue = Color(0xFF3157D5);
  static const sky = Color(0xFFEAF0FF);
  static const canvas = Color(0xFFF5F7FB);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E8F0);
  static const gold = Color(0xFFB7791F);
  static const cream = Color(0xFFFFF8E8);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: Brightness.light,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
    fontFamily: 'sans-serif',
    textTheme: const TextTheme(
      headlineLarge: TextStyle(fontSize: 31, height: 1.08, fontWeight: FontWeight.w800, color: AppColors.ink),
      headlineMedium: TextStyle(fontSize: 25, height: 1.15, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
      titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink),
      bodyMedium: TextStyle(fontSize: 14, height: 1.5, color: AppColors.ink),
      bodySmall: TextStyle(fontSize: 12, height: 1.4, color: AppColors.muted),
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: Colors.white,
      indicatorColor: AppColors.sky,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? AppColors.blue : AppColors.muted,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
