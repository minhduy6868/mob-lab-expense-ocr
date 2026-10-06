import 'package:flutter/material.dart';

class AppTheme {
  // VKU Navy Seed Color from Lecture Slide 32
  static const Color vkuNavy = Color(0xFF2C4570);
  static const Color vkuGold = Color(0xFFEAA221);
  static const Color vkuRed = Color(0xFFC62828);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vkuNavy,
      brightness: Brightness.light,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 3,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: vkuNavy.withValues(alpha: 0.15),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: vkuNavy,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 3,
      shape: StadiumBorder(),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 3,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      indicatorColor: vkuNavy.withValues(alpha: 0.35),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
