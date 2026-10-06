import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // VKU Navy Seed Color from Lecture Slide 32
  static const Color vkuNavy = Color(0xFF1E3A8A); // Deep Navy
  static const Color vkuGold = Color(0xFFF59E0B); // Amber / Gold
  static const Color vkuRed = Color(0xFFDC2626);  // Accent Crimson

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vkuNavy,
      brightness: Brightness.light,
      primary: const Color(0xFF1E3A8A),
      secondary: const Color(0xFF0D9488),
      surface: const Color(0xFFF8FAFC),
    ),
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1.5,
      backgroundColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0.8,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: const Color(0xFF1E3A8A),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 4,
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFF1E3A8A).withValues(alpha: 0.12),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF1E3A8A));
        }
        return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF64748B));
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vkuNavy,
      brightness: Brightness.dark,
      primary: const Color(0xFF60A5FA),
      secondary: const Color(0xFF2DD4BF),
      surface: const Color(0xFF0F172A),
    ),
    scaffoldBackgroundColor: const Color(0xFF0B0F19),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 1.5,
      backgroundColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF8FAFC),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 1,
      color: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFF334155),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 4,
      backgroundColor: const Color(0xFF3B82F6),
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 4,
      backgroundColor: const Color(0xFF111827),
      indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF60A5FA));
        }
        return GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF94A3B8));
      }),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF475569)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF60A5FA), width: 1.8),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
