/// Creator portal admin profile screen (placeholder).
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../widgets/admin_bottom_nav.dart';

/// Displays admin profile and settings.
class AdminProfileScreen extends StatelessWidget {
  /// Creates the admin profile screen.
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: const <Widget>[NotificationBell()],
      ),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.profile),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, size: 48, color: AppColors.primaryBlue),
            ),
            const SizedBox(height: 16),
            Text(
              'Admin Profile',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Profile settings coming soon.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
