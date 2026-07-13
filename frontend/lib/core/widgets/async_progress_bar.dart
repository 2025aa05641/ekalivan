/// Typed progress UI for long-running video generation.
import 'package:flutter/material.dart';

import 'accessible_text.dart';

/// Renders generation progress in plain student-friendly language.
class AsyncProgressBar extends StatelessWidget {
  /// Creates a progress indicator from an API progress event.
  const AsyncProgressBar({super.key, required this.progress, required this.label});

  /// Completion percentage between zero and one hundred.
  final double progress;

  /// Plain-language current stage.
  final String label;

  @override
  Widget build(BuildContext context) {
    final double value = (progress / 100).clamp(0, 1).toDouble();
    return Semantics(
      label: '$label: ${progress.round()} percent complete',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AccessibleText(label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value, minHeight: 12),
        ],
      ),
    );
  }
}
