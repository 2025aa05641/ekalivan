/// Root application composition.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/video_generator/presentation/providers/router_provider.dart';

/// Configures the application theme and named routing.
class TextbookVideoApp extends ConsumerWidget {
  /// Creates the root application widget.
  const TextbookVideoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Learn with Videos',
      theme: AppTheme.lightTheme,
      routerConfig: ref.watch(routerProvider),
      debugShowCheckedModeBanner: false,
    );
  }
}
