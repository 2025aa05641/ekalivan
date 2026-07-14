/// Primary call-to-action button with the Ekalivan gradient treatment.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// Full-width gradient button used for the main action on a screen.
class PrimaryButton extends StatelessWidget {
  /// Creates the primary button.
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.loading = false});

  /// Button text.
  final String label;

  /// Tap handler; the button renders disabled when null.
  final VoidCallback? onPressed;

  /// Shows a progress indicator instead of [label] while true.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !loading;
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SizedBox(
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: enabled ? tokens.primaryButtonGradient : null,
            color: enabled ? null : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(tokens.buttonRadius),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              borderRadius: BorderRadius.circular(tokens.buttonRadius),
              onTap: enabled ? onPressed : null,
              child: Center(
                child: loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(label, style: Theme.of(context).textTheme.labelLarge),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
