/// Ekalivan theme: blue/purple palette, Poppins typography, and the custom
/// design tokens in [EkalivanThemeExtension].
///
/// Source of truth: `frontend/Mockup/UI_DESIGN_SYSTEM.md` and
/// `frontend/Mockup/MockupImages.JPEG`.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_theme_extension.dart';
import 'app_typography.dart';

/// Creates the shared visual language for the client.
abstract final class AppTheme {
  /// Light theme built from the Ekalivan brand palette and typography.
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primaryBlue,
      onPrimary: Colors.white,
      secondary: AppColors.primaryPurple,
      onSecondary: Colors.white,
      surface: AppColors.background,
      onSurface: Color(0xFF0F172A),
      error: AppColors.danger,
      onError: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: AppTypography.textTheme(colorScheme.onSurface),
      cardTheme: const CardThemeData(elevation: 0, margin: EdgeInsets.zero, color: AppColors.card),
      extensions: const <ThemeExtension<dynamic>>[EkalivanThemeExtension.standard],
    );
  }
}
