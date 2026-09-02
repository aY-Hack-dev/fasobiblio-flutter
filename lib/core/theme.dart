import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppColors {
  static const ink = Color(0xFF0F172A);
  static const navy = Color(0xFF0F172A);
  static const blue = Color(0xFF1860F0);
  static const blueDeep = Color(0xFF0B3FB9);
  static const sky = Color(0xFFF0F5FF);
  static const canvas = Color(0xFFFFFFFF);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const gold = Color(0xFFB7791F);
  static const cream = Color(0xFFFFF8E8);
}

abstract final class AppTypography {
  static TextStyle bookTitle({double size = 24, Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.urbanist(fontSize: size, height: 1.18, fontWeight: weight, color: color, letterSpacing: -.2);

  static TextStyle editorial({double size = 20, Color? color, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.urbanist(fontSize: size, height: 1.2, fontWeight: weight, color: color, letterSpacing: -.2);

  static TextStyle display({double size = 20, Color? color, FontWeight weight = FontWeight.w800}) =>
      GoogleFonts.urbanist(fontSize: size, height: 1.15, fontWeight: weight, color: color, letterSpacing: -.25);
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
  final baseText = GoogleFonts.spaceGroteskTextTheme(ThemeData(brightness: brightness).textTheme).apply(
    bodyColor: textColor,
    displayColor: textColor,
  );
  final textTheme = baseText.copyWith(
    headlineLarge: GoogleFonts.urbanist(fontSize: 28, height: 1.08, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -.35),
    headlineMedium: GoogleFonts.urbanist(fontSize: 22, height: 1.14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -.3),
    titleLarge: GoogleFonts.urbanist(fontSize: 18, height: 1.2, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -.2),
    titleMedium: GoogleFonts.urbanist(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
    bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
    bodySmall: baseText.bodySmall?.copyWith(fontSize: 11, height: 1.4),
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    scaffoldBackgroundColor: canvas,
    fontFamily: GoogleFonts.spaceGrotesk().fontFamily,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      centerTitle: false,
      backgroundColor: surface,
      foregroundColor: textColor,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.urbanist(fontSize: 17, fontWeight: FontWeight.w800, color: textColor, letterSpacing: -.2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 66,
      backgroundColor: surface,
      indicatorColor: AppColors.sky,
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        fontSize: 10,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
        color: states.contains(WidgetState.selected) ? AppColors.blue : mutedColor,
      )),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: line)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.blue, width: 1.5)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.blue.withValues(alpha: .35),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size(0, 46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    ),
  );
}
