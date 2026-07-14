/// Ekalivan typography: Poppins with an Inter fallback.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the shared [TextTheme] using the design system's font weights:
/// Heading 700, Title 600, Body 400, Button 600. Never Roboto.
abstract final class AppTypography {
  /// Returns the app's [TextTheme], tinting all styles with [onSurface].
  static TextTheme textTheme(Color onSurface) {
    return TextTheme(
      headlineLarge: _poppins(fontSize: 28, fontWeight: FontWeight.w700, color: onSurface, height: 1.25),
      headlineMedium: _poppins(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface, height: 1.3),
      titleLarge: _poppins(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
      titleMedium: _poppins(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
      bodyLarge: _poppins(fontSize: 16, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      bodyMedium: _poppins(fontSize: 14, fontWeight: FontWeight.w400, color: onSurface, height: 1.5),
      labelLarge: _poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    );
  }

  static TextStyle _poppins({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? height,
  }) {
    final TextStyle style = GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
    return style.copyWith(fontFamilyFallback: <String>[GoogleFonts.inter().fontFamily ?? 'Inter']);
  }
}
