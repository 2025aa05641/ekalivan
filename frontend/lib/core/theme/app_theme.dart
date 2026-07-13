/// High-contrast theme tokens for child-first learning screens.
import 'package:flutter/material.dart';

/// Creates the shared visual language for the client.
abstract final class AppTheme {
  /// High-contrast light theme with readable typography and large touch targets.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: Color(0xFF075985),
      onPrimary: Colors.white,
      secondary: Color(0xFFF97316),
      onSecondary: Colors.white,
      surface: Color(0xFFF8FAFC),
      onSurface: Color(0xFF0F172A),
      error: Color(0xFFB91C1C),
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.25),
        bodyLarge: TextStyle(fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(fontSize: 16, height: 1.5),
      ),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero),
    );
  }
}
