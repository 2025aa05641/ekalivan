/// Creator portal landing screen: at-a-glance metrics and recent activity.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../widgets/admin_bottom_nav.dart';

/// One row in the "Recent Activity" list.
class _RecentActivity {
  const _RecentActivity({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.taskId,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final StatusChipKind status;
  final String taskId;
}

const List<_RecentActivity> _recentActivity = <_RecentActivity>[
  _RecentActivity(
    icon: Icons.eco_rounded,
    title: 'Science Std 6',
    subtitle: 'The World of Plants',
    status: StatusChipKind.success,
    taskId: 'mock-science-6',
  ),
  _RecentActivity(
    icon: Icons.calculate_rounded,
    title: 'Maths Std 7',
    subtitle: 'Integers',
    status: StatusChipKind.success,
    taskId: 'mock-maths-7',
  ),
  _RecentActivity(
    icon: Icons.translate_rounded,
    title: 'Tamil Std 8',
    subtitle: 'எழுத்து - 1',
    status: StatusChipKind.inProgress,
    taskId: 'mock-tamil-8',
  ),
  _RecentActivity(
    icon: Icons.public_rounded,
    title: 'Social Science Std 6',
    subtitle: 'Our Earth',
    status: StatusChipKind.neutral,
    taskId: 'mock-social-6',
  ),
];

/// Creator portal home screen, showing summary metrics and recent uploads.
class AdminDashboardScreen extends ConsumerWidget {
  /// Creates the admin dashboard screen.
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentJobsAsync = ref.watch(recentJobsProvider);
    final myVideosAsync = ref.watch(myVideosProvider);

    // Derive counts from real data where available, fall back to mock values.
    final int realJobCount = recentJobsAsync.valueOrNull?.length ?? 0;
    final int processingCount = recentJobsAsync.valueOrNull
            ?.where((j) => j.status == 'PROCESSING' || j.status == 'QUEUED')
            .length ??
        0;
    final int publishedCount = myVideosAsync.valueOrNull?.length ?? 0;

    final int totalBooksCount = realJobCount > 0 ? realJobCount : 24;
    final int totalVideosCount = publishedCount > 0 ? publishedCount : 156;
    final int processingFinal = processingCount > 0 ? processingCount : 8;

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        automaticallyImplyLeading: false,
        actions: const <Widget>[NotificationBell()],
      ),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.dashboard),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // Metric row — each card is tappable and navigates to its section
          Row(
            children: <Widget>[
              Expanded(
                child: _MetricCard(
                  value: totalBooksCount.toString(),
                  label: 'Total Books',
                  color: AppColors.primaryBlue,
                  onTap: () => context.goNamed(AppRoute.adminBooks.routeName),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: totalVideosCount.toString(),
                  label: 'Total Videos',
                  color: AppColors.primaryPurple,
                  onTap: () => context.goNamed(AppRoute.adminVideos.routeName),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _MetricCard(
                  value: processingFinal.toString(),
                  label: 'Processing',
                  color: AppColors.warning,
                  onTap: () => context.goNamed(AppRoute.adminPipelines.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recent Activity', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _recentActivity.length; i++) ...<Widget>[
                  _RecentActivityTile(activity: _recentActivity[i]),
                  if (i < _recentActivity.length - 1)
                    const Divider(height: 1, indent: 16, endIndent: 16),
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

/// Compact metric tile with large centered number. Tapping navigates to the
/// corresponding section screen.
class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 4),
              Icon(Icons.arrow_forward_rounded, color: color.withValues(alpha: 0.4), size: 13),
            ],
          ),
        ),
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
    return InkWell(
      onTap: () => context.goNamed(AppRoute.adminPipelines.routeName),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(activity.icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    activity.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  Text(
                    activity.subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(label: statusLabel, kind: activity.status),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
