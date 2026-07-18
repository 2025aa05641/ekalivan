/// Rounded text input matching the Ekalivan design system.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_extension.dart';

/// Text field with the design system's rounded, bordered treatment.
///
/// When [darkBackground] is true the field is rendered with a semi-transparent
/// white fill and white label/text, suitable for use on the dark login screen.
class RoundedInput extends StatelessWidget {
  /// Creates the rounded input.
  const RoundedInput({
    super.key,
    required this.label,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.darkBackground = false,
    this.prefixIcon,
  });

  /// Field label / hint text.
  final String label;

  /// Optional controller.
  final TextEditingController? controller;

  /// Whether to obscure input (for passwords).
  final bool obscureText;

  /// Keyboard type hint.
  final TextInputType? keyboardType;

  /// Whether the field is on a dark background (login screen).
  final bool darkBackground;

  /// Optional leading icon.
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;

    if (darkBackground) {
      final OutlineInputBorder border = OutlineInputBorder(
        borderRadius: BorderRadius.circular(tokens.textFieldRadius),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
      );
      return TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.12),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.7), size: 20)
              : null,
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: Colors.white, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      );
    }

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
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.primaryBlue, size: 20) : null,
        filled: true,
        fillColor: AppColors.card,
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5)),
      ),
    );
  }
}
