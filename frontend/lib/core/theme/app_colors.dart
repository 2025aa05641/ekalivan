/// Ekalivan brand color palette.
///
/// Values come from `frontend/Mockup/UI_DESIGN_SYSTEM.md`, the written
/// design-system spec paired with the approved UI mockup.
library;

import 'package:flutter/material.dart';

/// Static brand colors used to build the app's [ColorScheme] and gradients.
abstract final class AppColors {
  /// Primary Blue.
  static const Color primaryBlue = Color(0xFF0D3B73);

  /// Secondary Blue.
  static const Color secondaryBlue = Color(0xFF144A92);

  /// Primary Purple.
  static const Color primaryPurple = Color(0xFF7E3FF2);

  /// Accent Purple.
  static const Color accentPurple = Color(0xFFA855F7);

  /// Screen background.
  static const Color background = Color(0xFFF6F8FC);

  /// Card background.
  static const Color card = Color(0xFFFFFFFF);

  /// Hairline border.
  static const Color border = Color(0xFFE9EEF5);

  /// Success/completed state.
  static const Color success = Color(0xFF31C46C);

  /// Warning/in-progress state.
  static const Color warning = Color(0xFFF4B942);

  /// Danger/error state.
  static const Color danger = Color(0xFFF25B5B);
}
