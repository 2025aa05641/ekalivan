/// Custom design tokens not covered by [ThemeData]'s built-in properties.
library;

import 'package:flutter/material.dart';

import 'app_gradients.dart';
import 'app_radius.dart';
import 'app_shadows.dart';

/// Gradients, shadows, and radii from the Ekalivan design system, accessed
/// via `Theme.of(context).extension<EkalivanThemeExtension>()`.
@immutable
class EkalivanThemeExtension extends ThemeExtension<EkalivanThemeExtension> {
  /// Creates the extension with its token values.
  const EkalivanThemeExtension({
    required this.headerGradient,
    required this.primaryButtonGradient,
    required this.softShadow,
    required this.buttonRadius,
    required this.cardRadius,
    required this.dialogRadius,
    required this.bottomSheetRadius,
    required this.textFieldRadius,
  });

  /// Default token values matching the design system.
  static const EkalivanThemeExtension standard = EkalivanThemeExtension(
    headerGradient: AppGradients.header,
    primaryButtonGradient: AppGradients.primaryButton,
    softShadow: AppShadows.soft,
    buttonRadius: AppRadius.button,
    cardRadius: AppRadius.card,
    dialogRadius: AppRadius.dialog,
    bottomSheetRadius: AppRadius.bottomSheet,
    textFieldRadius: AppRadius.textField,
  );

  /// Blue gradient used on screen headers.
  final Gradient headerGradient;

  /// Blue-to-purple gradient used on primary buttons.
  final Gradient primaryButtonGradient;

  /// Soft shadow applied to cards and floating surfaces.
  final List<BoxShadow> softShadow;

  /// Button corner radius.
  final double buttonRadius;

  /// Card corner radius.
  final double cardRadius;

  /// Dialog corner radius.
  final double dialogRadius;

  /// Bottom sheet corner radius.
  final double bottomSheetRadius;

  /// Text field corner radius.
  final double textFieldRadius;

  @override
  EkalivanThemeExtension copyWith({
    Gradient? headerGradient,
    Gradient? primaryButtonGradient,
    List<BoxShadow>? softShadow,
    double? buttonRadius,
    double? cardRadius,
    double? dialogRadius,
    double? bottomSheetRadius,
    double? textFieldRadius,
  }) {
    return EkalivanThemeExtension(
      headerGradient: headerGradient ?? this.headerGradient,
      primaryButtonGradient: primaryButtonGradient ?? this.primaryButtonGradient,
      softShadow: softShadow ?? this.softShadow,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      cardRadius: cardRadius ?? this.cardRadius,
      dialogRadius: dialogRadius ?? this.dialogRadius,
      bottomSheetRadius: bottomSheetRadius ?? this.bottomSheetRadius,
      textFieldRadius: textFieldRadius ?? this.textFieldRadius,
    );
  }

  @override
  EkalivanThemeExtension lerp(ThemeExtension<EkalivanThemeExtension>? other, double t) {
    if (other is! EkalivanThemeExtension) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}
