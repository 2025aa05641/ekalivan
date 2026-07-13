/// Named, type-safe route ownership through Riverpod.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';

/// Application routes. Named routes avoid raw route strings in feature widgets.
enum AppRoute {
  /// Top-level subject selection route.
  home('/', 'home');

  /// Creates a named application route.
  const AppRoute(this.path, this.routeName);

  /// URL path.
  final String path;

  /// GoRouter route name.
  final String routeName;
}

/// Provides the immutable router configuration.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => GoRouter(
    initialLocation: AppRoute.home.path,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.routeName,
        builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
      ),
    ],
  ),
);
