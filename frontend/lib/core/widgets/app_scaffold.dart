/// Shared scaffold applying the Ekalivan background and structure.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Base scaffold used by every Ekalivan screen for a consistent background.
class AppScaffold extends StatelessWidget {
  /// Creates the scaffold.
  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.safeArea = true,
  });

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Screen content.
  final Widget body;

  /// Optional floating bottom navigation bar.
  final Widget? bottomNavigationBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Whether to wrap [body] in a [SafeArea]. Disable for screens that need
  /// content (e.g. a gradient header) to extend under the status bar.
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: appBar,
      body: safeArea ? SafeArea(child: body) : body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
