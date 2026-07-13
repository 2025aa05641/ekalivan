/// Large, tap-safe subject selection card.
import 'package:flutter/material.dart';

import '../../../../core/widgets/accessible_text.dart';

/// Presents a subject as a large accessible navigation target.
class AdaptiveSubjectCard extends StatelessWidget {
  /// Creates an adaptive subject card.
  const AdaptiveSubjectCard({super.key, required this.title, required this.color, required this.onTap});

  /// Subject name.
  final String title;

  /// Visual category color.
  final Color color;

  /// Navigation callback, invoked by one tap only.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Choose $title',
      child: Card(
        color: color,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: AccessibleText(title, style: Theme.of(context).textTheme.headlineLarge),
          ),
        ),
      ),
    );
  }
}
