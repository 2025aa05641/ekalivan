/// Bottom navigation shared by the Student portal's top-level screens.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/bottom_nav.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// Destinations on the Student portal's floating bottom navigation bar.
enum StudentNavDestination {
  /// Medium selection (the student portal's home).
  home(Icons.home_rounded, 'Home', AppRoute.studentMedium),

  /// Previously watched videos.
  myVideos(Icons.video_library_rounded, 'My Videos', AppRoute.myVideos),

  /// Downloaded-for-offline videos.
  downloads(Icons.download_rounded, 'Downloads', AppRoute.studentDownloads),

  /// Student profile.
  profile(Icons.person_rounded, 'Profile', AppRoute.studentProfile);

  const StudentNavDestination(this.icon, this.label, this.route);

  /// Icon shown on the bar.
  final IconData icon;

  /// Label shown under the icon.
  final String label;

  /// Route navigated to when tapped, or null for not-yet-built destinations.
  final AppRoute? route;
}

/// Wraps [BottomNav] with the Student portal's fixed destination set.
class StudentBottomNav extends StatelessWidget {
  /// Creates the student bottom navigation bar.
  const StudentBottomNav({super.key, required this.current});

  /// Currently active destination.
  final StudentNavDestination current;

  @override
  Widget build(BuildContext context) {
    return BottomNav(
      items: <BottomNavItem>[
        for (final StudentNavDestination destination in StudentNavDestination.values)
          BottomNavItem(icon: destination.icon, label: destination.label),
      ],
      currentIndex: current.index,
      onTap: (int index) {
        final AppRoute? route = StudentNavDestination.values[index].route;
        if (route != null) {
          context.goNamed(route.routeName);
        }
      },
    );
  }
}
