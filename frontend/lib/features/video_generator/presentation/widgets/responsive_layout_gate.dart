/// Single responsive breakpoint gate for phone and tablet layouts.
import 'package:flutter/widgets.dart';

/// Selects a phone or tablet body at the architecture-defined 600px breakpoint.
class ResponsiveLayoutGate extends StatelessWidget {
  /// Creates the responsive layout gate.
  const ResponsiveLayoutGate({super.key, required this.phone, required this.tablet});

  /// Widget rendered below 600 logical pixels.
  final Widget phone;

  /// Widget rendered at and above 600 logical pixels.
  final Widget tablet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return constraints.maxWidth >= 600 ? tablet : phone;
      },
    );
  }
}
