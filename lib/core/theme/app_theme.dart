import 'package:flutter/material.dart';

class WorkConnectTheme {
  static ThemeData get light {
    final base = ThemeData.light();
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0057FF),
        primary: const Color(0xFF0057FF),
        secondary: const Color(0xFF23A094),
        tertiary: const Color(0xFFFFB74D),
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2A44),
        elevation: 0.5,
        centerTitle: false,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFFEAF0FF),
        selectedColor: const Color(0xFF0057FF),
        secondaryLabelStyle: const TextStyle(color: Colors.white),
      ),
      textTheme: _buildTextTheme(base.textTheme),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: const Color(0xFF0057FF),
        foregroundColor: Colors.white,
      ),
      snackBarTheme: base.snackBarTheme.copyWith(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      headlineLarge: base.headlineLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2A44),
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: const Color(0xFF1F2A44),
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2A44),
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2A44),
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1F2A44),
      ),
      bodyLarge: base.bodyLarge?.copyWith(color: const Color(0xFF3C4858)),
      bodyMedium: base.bodyMedium?.copyWith(color: const Color(0xFF3C4858)),
      labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
