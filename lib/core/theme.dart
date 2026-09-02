import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

abstract final class AppColors {
  static const ink = Color(0xFF0F172A);
  static const navy = Color(0xFF0F172A);
  static const blue = Color(0xFF1860F0);
  static const blueDeep = Color(0xFF0B3FB9);
  static const sky = Color(0xFFF0F5FF);
  static const canvas = Color(0xFFF7F9FD);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);
  static const gold = Color(0xFFB7791F);
  static const cream = Color(0xFFFFF8E8);
}

/// Une seule famille d’icônes dans toute l’application.
abstract final class AppIcons {
  static const checkCircle = LucideIcons.circleCheck;
  static const info = LucideIcons.info;
  static const home = LucideIcons.house;
  static const library = LucideIcons.libraryBig;
  static const user = LucideIcons.userRound;
  static const search = LucideIcons.search;
  static const premium = LucideIcons.crown;
  static const sparkles = LucideIcons.sparkles;
  static const send = LucideIcons.send;
  static const bot = LucideIcons.bot;
  static const lock = LucideIcons.lockKeyhole;
  static const phone = LucideIcons.phone;
  static const smartphone = LucideIcons.smartphone;
  static const bookOpen = LucideIcons.bookOpen;
  static const bookmark = LucideIcons.bookmark;
  static const message = LucideIcons.messageCircle;
  static const review = LucideIcons.messageSquareText;
  static const download = LucideIcons.download;
  static const fileCheck = LucideIcons.fileCheck;
  static const heart = LucideIcons.heart;
  static const share = LucideIcons.share2;
  static const star = LucideIcons.star;
  static const eye = LucideIcons.eye;
  static const arrowRight = LucideIcons.arrowRight;
  static const chevronRight = LucideIcons.chevronRight;
  static const grid = LucideIcons.grid2X2;
  static const brain = LucideIcons.brainCircuit;
  static const filters = LucideIcons.slidersHorizontal;
  static const cloudSync = LucideIcons.cloudSync;
  static const shoppingBag = LucideIcons.shoppingBag;
  static const bellOff = LucideIcons.bellOff;
  static const bell = LucideIcons.bell;
  static const account = LucideIcons.circleUserRound;
  static const close = LucideIcons.x;
  static const verified = LucideIcons.badgeCheck;
  static const wallet = LucideIcons.walletCards;
  static const scale = LucideIcons.scale;
  static const moon = LucideIcons.moon;
  static const sun = LucideIcons.sun;
  static const fileText = LucideIcons.fileText;
  static const lightbulb = LucideIcons.lightbulb;
  static const more = LucideIcons.ellipsis;
  static const shield = LucideIcons.shieldCheck;
  static const support = LucideIcons.headset;
  static const logout = LucideIcons.logOut;
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
  final canvas = dark ? const Color(0xFF090F1D) : AppColors.canvas;
  final line = dark ? const Color(0xFF30363D) : AppColors.line;
  final baseText = GoogleFonts.spaceGroteskTextTheme(ThemeData(brightness: brightness).textTheme).apply(
    bodyColor: textColor,
    displayColor: textColor,
  );
  final textTheme = baseText.copyWith(
    headlineLarge: GoogleFonts.urbanist(fontSize: 25, height: 1.08, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -.35),
    headlineMedium: GoogleFonts.urbanist(fontSize: 20, height: 1.14, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -.3),
    titleLarge: GoogleFonts.urbanist(fontSize: 17, height: 1.2, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -.2),
    titleMedium: GoogleFonts.urbanist(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
    bodyMedium: baseText.bodyMedium?.copyWith(fontSize: 12.5, height: 1.45),
    bodySmall: baseText.bodySmall?.copyWith(fontSize: 10.5, height: 1.4),
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
    dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 18,
      showDragHandle: true,
      dragHandleColor: dark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      constraints: const BoxConstraints(maxWidth: 720),
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
