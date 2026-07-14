/// Gradient presets from the Ekalivan design system.
library;

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Named gradients: blue for headers, blue-to-purple for primary buttons.
abstract final class AppGradients {
  /// Blue gradient used on screen headers (login, dashboard hero, etc.).
  static const LinearGradient header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[AppColors.primaryBlue, AppColors.secondaryBlue],
  );

  /// Blue-to-purple gradient used on primary call-to-action buttons.
  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: <Color>[AppColors.primaryBlue, AppColors.primaryPurple],
  );
}
