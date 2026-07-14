/// Soft shadow presets from the Ekalivan design system.
library;

import 'package:flutter/material.dart';

/// Very soft box shadows (blur 20, ~8% opacity black, y-offset 8), matching
/// the design system's instruction to avoid harsh Material shadows.
abstract final class AppShadows {
  /// Standard soft shadow applied to cards and floating surfaces.
  static const List<BoxShadow> soft = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(0, 8)),
  ];
}
