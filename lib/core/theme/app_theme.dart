import 'package:flutter/material.dart';
class AppColors {
  static const navy = Color(0xFF003250);
  static const green = Color(0xFF90C84C);
  static const bg = Color(0xFFF5F7F8);
  static const muted = Color(0xFF687986);
  static const border = Color(0xFFE0E7EB);
}
class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true, scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy, primary: AppColors.navy, secondary: AppColors.green),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.navy, foregroundColor: Colors.white),
    cardTheme: CardThemeData(color: Colors.white, elevation: 0, margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.border))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));
}
