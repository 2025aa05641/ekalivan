/// Small colored status pill (e.g. "Completed", "Processing", "Queued").
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Semantic status for [StatusChip]'s color coding.
enum StatusChipKind {
  /// Positive/finished state — success green.
  success,

  /// In-progress state — warning amber.
  inProgress,

  /// Not-yet-started state — neutral gray.
  neutral,

  /// Failure state — danger red.
  danger,
}

/// Compact rounded pill labeling an item's status.
class StatusChip extends StatelessWidget {
  /// Creates the status chip.
  const StatusChip({super.key, required this.label, required this.kind});

  /// Chip text, e.g. "Completed".
  final String label;

  /// Semantic kind controlling the chip's color.
  final StatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (kind) {
      StatusChipKind.success => AppColors.success,
      StatusChipKind.inProgress => AppColors.warning,
      StatusChipKind.neutral => Colors.grey.shade500,
      StatusChipKind.danger => AppColors.danger,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
