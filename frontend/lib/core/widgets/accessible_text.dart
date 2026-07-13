/// Accessible text primitive with consistent reading defaults.
import 'package:flutter/material.dart';

/// Renders high-contrast text with a consistent readable line height.
class AccessibleText extends StatelessWidget {
  /// Creates an accessible text widget.
  const AccessibleText(this.data, {super.key, this.style, this.textAlign});

  /// Text to render.
  final String data;

  /// Optional semantic typography from the surrounding theme.
  final TextStyle? style;

  /// Optional alignment for the rendered text.
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(data, style: style, textAlign: textAlign, strutStyle: const StrutStyle(height: 1.5));
  }
}
