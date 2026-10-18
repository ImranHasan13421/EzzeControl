import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors
  static const Color background = Color(0xFF121417);
  static const Color surface = Color(0xFF1A1D23);
  static const Color surfaceLight = Color(0xFF22262E);
  static const Color surfaceDark = Color(0xFF0F1114);

  // Menu Tile Colors (Matching 1st image)
  static const Color tilePaired = Color(0xFF485E5A);
  static const Color tileBt = Color(0xFF675854);
  static const Color tileSettings = Color(0xFF3B4A5C);
  static const Color tileGuide = Color(0xFF282D34);

  // Accent Colors
  static const Color blueAccent = Color(0xFF2563EB);
  static const Color blueLight = Color(0xFF3B82F6);
  static const Color greenSuccess = Color(0xFF22C55E);
  static const Color redDanger = Color(0xFFEF4444);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // Touchpad Surface
  static const Color touchpadBg = Color(0xFF23262D);
  static const Color touchpadBorder = Color(0xFF2E333D);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: blueAccent,
      colorScheme: const ColorScheme.dark(
        primary: blueAccent,
        secondary: blueLight,
        surface: surface,
        error: redDanger,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFFF0F4F8), // Matching the light dialogs in 3rd, 8th, 10th images
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
