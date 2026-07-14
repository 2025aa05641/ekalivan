/// Creator portal landing screen: at-a-glance metrics and recent activity.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/admin_bottom_nav.dart';

/// One row in the "Recent Activity" list.
class _RecentActivity {
  const _RecentActivity({required this.icon, required this.title, required this.subtitle, required this.status});

  final IconData icon;
  final String title;
  final String subtitle;
  final StatusChipKind status;
}

const List<_RecentActivity> _recentActivity = <_RecentActivity>[
  _RecentActivity(
    icon: Icons.eco_rounded,
    title: 'Science Std 6',
    subtitle: 'The World of Plants',
    status: StatusChipKind.success,
  ),
  _RecentActivity(icon: Icons.calculate_rounded, title: 'Maths Std 7', subtitle: 'Integers', status: StatusChipKind.success),
  _RecentActivity(
    icon: Icons.translate_rounded,
    title: 'Tamil Std 8',
    subtitle: '@ழுத்து - 1',
    status: StatusChipKind.inProgress,
  ),
  _RecentActivity(
    icon: Icons.public_rounded,
    title: 'Social Science Std 6',
    subtitle: 'Our Earth',
    status: StatusChipKind.neutral,
  ),
];

/// Creator portal home screen, showing summary metrics and recent uploads.
///
/// UI only (Phase 3): metric values and the activity list are mock data,
/// replaced with real backend data in Phase 4.
class AdminDashboardScreen extends StatelessWidget {
  /// Creates the admin dashboard screen.
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Admin Dashboard'), actions: const <Widget>[
        Padding(padding: EdgeInsets.only(right: AppSpacing.md), child: Icon(Icons.notifications_none_rounded)),
      ]),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.dashboard),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const Row(
            children: <Widget>[
              Expanded(child: MetricCard(icon: Icons.menu_book_rounded, value: '24', label: 'Total Books')),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: MetricCard(icon: Icons.smart_display_rounded, value: '156', label: 'Total Videos')),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: MetricCard(icon: Icons.hourglass_top_rounded, value: '8', label: 'Processing')),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _recentActivity.length; i++) ...<Widget>[
                  if (i > 0) const Divider(height: AppSpacing.lg),
                  _RecentActivityTile(activity: _recentActivity[i]),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: '+ Upload New Book',
            onPressed: () => context.goNamed(AppRoute.adminUpload.routeName),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityTile extends StatelessWidget {
  const _RecentActivityTile({required this.activity});

  final _RecentActivity activity;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = switch (activity.status) {
      StatusChipKind.success => 'Completed',
      StatusChipKind.inProgress => 'Processing',
      StatusChipKind.neutral => 'Queued',
      StatusChipKind.danger => 'Failed',
    };
    return Row(
      children: <Widget>[
        Icon(activity.icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(activity.title, style: Theme.of(context).textTheme.titleMedium),
              Text(activity.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
            ],
          ),
        ),
        StatusChip(label: statusLabel, kind: activity.status),
      ],
    );
  }
}
