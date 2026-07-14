/// Secondary (outlined) button used for lower-emphasis actions.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_extension.dart';

/// White, blue-outlined button used alongside a [PrimaryButton].
class SecondaryButton extends StatelessWidget {
  /// Creates the secondary button.
  const SecondaryButton({super.key, required this.label, required this.onPressed});

  /// Button text.
  final String label;

  /// Tap handler; the button renders disabled when null.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(tokens.buttonRadius)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: AppColors.primaryBlue),
        ),
      ),
    );
  }
}
