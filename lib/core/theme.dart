import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const ink = Color(0xFF101828);
  static const navy = Color(0xFF102A43);
  static const blue = Color(0xFF0866F5);
  static const blueDeep = Color(0xFF0647B8);
  static const sky = Color(0xFFEAF3FF);
  static const canvas = Color(0xFFF5F7FB);
  static const muted = Color(0xFF667085);
  static const line = Color(0xFFE4E8F0);
  static const gold = Color(0xFFB7791F);
  static const cream = Color(0xFFFFF8E8);
}

abstract final class AppTypography {
  static TextStyle bookTitle({double size = 24, Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.lora(fontSize: size, height: 1.16, fontWeight: weight, color: color);

  static TextStyle editorial({double size = 20, Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.sourceSerif4(fontSize: size, height: 1.2, fontWeight: weight, color: color);
}

ThemeData buildTheme({Brightness brightness = Brightness.light}) {
  final seededScheme = ColorScheme.fromSeed(
    seedColor: AppColors.blue,
    brightness: brightness,
    surface: brightness == Brightness.light ? Colors.white : const Color(0xFF161B22),
  );
  final scheme = seededScheme.copyWith(
    primary: AppColors.blue,
    onPrimary: Colors.white,
    secondary: AppColors.blue,
    primaryContainer: AppColors.sky,
    onPrimaryContainer: AppColors.blueDeep,
  );
  final dark = brightness == Brightness.dark;
  final textColor = dark ? const Color(0xFFE6EDF3) : AppColors.ink;
  final mutedColor = dark ? const Color(0xFF9AA4B2) : AppColors.muted;
  final surface = dark ? const Color(0xFF161B22) : Colors.white;
  final canvas = dark ? const Color(0xFF0D1117) : AppColors.canvas;
  final line = dark ? const Color(0xFF30363D) : AppColors.line;
  final baseText = GoogleFonts.manropeTextTheme(ThemeData(brightness: brightness).textTheme).apply(
    bodyColor: textColor,
    displayColor: textColor,
  );
  final textTheme = baseText.copyWith(
    headlineLarge: baseText.headlineLarge?.copyWith(fontSize: 31, height: 1.08, fontWeight: FontWeight.w800),
    headlineMedium: baseText.headlineMedium?.copyWith(fontSize: 25, height: 1.15, fontWeight: FontWeight.w800),
    titleLarge: baseText.titleLarge?.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
    titleMedium: baseText.titleMedium?.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
    bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 14, height: 1.5),
    bodySmall: baseText.bodySmall?.copyWith(fontSize: 12, height: 1.4),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: canvas,
    fontFamily: GoogleFonts.manrope().fontFamily,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      backgroundColor: surface,
      indicatorColor: AppColors.sky,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? AppColors.blue : mutedColor,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.blue.withValues(alpha: .35),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}
