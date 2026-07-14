/// Blue gradient header banner used atop hero/dashboard screens.
library;

import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_theme_extension.dart';

/// Full-width blue gradient banner, typically holding a title and icon.
class GradientHeader extends StatelessWidget {
  /// Creates the gradient header.
  const GradientHeader({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.lg)});

  /// Content laid out over the gradient.
  final Widget child;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(gradient: tokens.headerGradient),
      child: child,
    );
  }
}
