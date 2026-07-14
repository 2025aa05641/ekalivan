/// Small stat card showing one icon, value, and label (e.g. "Total Books 24").
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'dashboard_card.dart';

/// Compact metric tile used in dashboard summary rows.
class MetricCard extends StatelessWidget {
  /// Creates the metric card.
  const MetricCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor = AppColors.primaryBlue,
  });

  /// Leading icon.
  final IconData icon;

  /// Large numeric/short value text.
  final String value;

  /// Caption below the value.
  final String label;

  /// Icon tint.
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, color: iconColor),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
