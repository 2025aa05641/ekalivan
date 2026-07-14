/// Generic rounded, soft-shadow card used across dashboard-style screens.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme_extension.dart';

/// White card with the design system's radius, padding, and soft shadow.
class DashboardCard extends StatelessWidget {
  /// Creates the dashboard card.
  const DashboardCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpacing.md)});

  /// Card content.
  final Widget child;

  /// Padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        boxShadow: tokens.softShadow,
      ),
      child: child,
    );
  }
}
