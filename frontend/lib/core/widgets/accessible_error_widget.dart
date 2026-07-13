/// Accessible error presentation primitive.
import 'package:flutter/material.dart';

import 'accessible_text.dart';

/// Renders a high-contrast error message without exposing transport internals.
class AccessibleErrorWidget extends StatelessWidget {
  /// Creates the error component.
  const AccessibleErrorWidget({super.key, required this.message, this.onRetry});

  /// Safe message explaining what happened.
  final String message;

  /// Optional recovery action.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AccessibleText('Something went wrong', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              AccessibleText(message),
              if (onRetry != null) ...<Widget>[
                const SizedBox(height: 12),
                FilledButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
