/// Bottom navigation shared by the Creator portal's top-level screens.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/bottom_nav.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// Destinations on the Creator portal's floating bottom navigation bar.
enum AdminNavDestination {
  /// Admin dashboard.
  dashboard(Icons.dashboard_rounded, 'Dashboard', AppRoute.adminDashboard),

  /// Book library (placeholder — not yet a real screen).
  books(Icons.menu_book_rounded, 'Books', null),

  /// AI pipeline progress.
  pipeline(Icons.timeline_rounded, 'Pipeline', AppRoute.adminPipeline),

  /// Published videos (placeholder — not yet a real screen).
  videos(Icons.video_library_rounded, 'Videos', null),

  /// Admin profile (placeholder — not yet a real screen).
  profile(Icons.person_rounded, 'Profile', null);

  const AdminNavDestination(this.icon, this.label, this.route);

  /// Icon shown on the bar.
  final IconData icon;

  /// Label shown under the icon.
  final String label;

  /// Route navigated to when tapped, or null for not-yet-built destinations.
  final AppRoute? route;
}

/// Wraps [BottomNav] with the Creator portal's fixed destination set.
class AdminBottomNav extends StatelessWidget {
  /// Creates the admin bottom navigation bar.
  const AdminBottomNav({super.key, required this.current});

  /// Currently active destination.
  final AdminNavDestination current;

  @override
  Widget build(BuildContext context) {
    return BottomNav(
      items: <BottomNavItem>[
        for (final AdminNavDestination destination in AdminNavDestination.values)
          BottomNavItem(icon: destination.icon, label: destination.label),
      ],
      currentIndex: current.index,
      onTap: (int index) {
        final AppRoute? route = AdminNavDestination.values[index].route;
        if (route != null) {
          context.goNamed(route.routeName);
        }
      },
    );
  }
}
