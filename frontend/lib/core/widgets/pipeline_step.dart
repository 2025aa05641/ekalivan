/// One step in the AI pipeline progress list (Lesson Planner, Teacher, ...).
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lifecycle state of one pipeline step, matching the design system's
/// completed/current/pending color coding.
enum PipelineStepStatus {
  /// Step finished successfully.
  completed,

  /// Step actively running.
  current,

  /// Step not yet started.
  pending,
}

/// One row in the 8-step AI pipeline list (Lesson Planner, Teacher,
/// Storyboard, Narration, Video Rendering, Publishing, Quality Check,
/// Final Publish).
class PipelineStep extends StatelessWidget {
  /// Creates the pipeline step row.
  const PipelineStep({super.key, required this.stepNumber, required this.label, required this.status});

  /// 1-based step number.
  final int stepNumber;

  /// Step name, e.g. "Storyboard".
  final String label;

  /// Current lifecycle state.
  final PipelineStepStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      PipelineStepStatus.completed => AppColors.success,
      PipelineStepStatus.current => AppColors.primaryBlue,
      PipelineStepStatus.pending => Colors.grey.shade400,
    };
    final Widget indicator = switch (status) {
      PipelineStepStatus.completed => Icon(Icons.check_circle_rounded, color: color),
      PipelineStepStatus.current => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      PipelineStepStatus.pending => Icon(Icons.radio_button_unchecked_rounded, color: color),
    };
    return Semantics(
      label: '$label, ${status.name}',
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Text('$stepNumber', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ),
        title: Text(label),
        trailing: indicator,
      ),
    );
  }
}
