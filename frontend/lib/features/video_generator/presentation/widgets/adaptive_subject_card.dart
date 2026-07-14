/// Large, debounced, tap-safe subject selection card.
library;

import 'package:flutter/material.dart';

import '../../../../core/widgets/accessible_text.dart';

/// Presents a subject as a large, debounced, accessible navigation target.
class AdaptiveSubjectCard extends StatefulWidget {
  /// Creates an adaptive subject card.
  const AdaptiveSubjectCard({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
    this.enabled = true,
  });

  /// Subject name.
  final String title;

  /// Visual category color.
  final Color color;

  /// Navigation action. Debounced so a burst of taps triggers it once.
  final Future<void> Function() onTap;

  /// Whether this subject currently has a chapter available to generate.
  final bool enabled;

  @override
  State<AdaptiveSubjectCard> createState() => _AdaptiveSubjectCardState();
}

class _AdaptiveSubjectCardState extends State<AdaptiveSubjectCard> {
  bool _isProcessing = false;

  Future<void> _handleTap() async {
    if (_isProcessing) {
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canTap = widget.enabled && !_isProcessing;
    return Semantics(
      button: true,
      enabled: canTap,
      label: widget.enabled ? 'Choose ${widget.title}' : '${widget.title}, coming soon',
      child: Card(
        color: widget.enabled ? widget.color : widget.color.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: canTap ? _handleTap : null,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Stack(
              children: <Widget>[
                AccessibleText(widget.title, style: Theme.of(context).textTheme.headlineLarge),
                if (_isProcessing)
                  const Positioned(
                    right: 0,
                    top: 0,
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else if (!widget.enabled)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: AccessibleText('Coming soon', style: Theme.of(context).textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
