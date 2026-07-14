/// Rounded text input matching the Ekalivan design system.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_extension.dart';

/// Text field with the design system's rounded, bordered treatment.
class RoundedInput extends StatelessWidget {
  /// Creates the rounded input.
  const RoundedInput({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
  });

  /// Field label / hint text.
  final String label;

  /// Optional controller.
  final TextEditingController? controller;

  /// Whether to obscure input (for passwords).
  final bool obscureText;

  /// Keyboard type hint.
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.textFieldRadius),
      borderSide: const BorderSide(color: AppColors.border),
    );
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }
}
