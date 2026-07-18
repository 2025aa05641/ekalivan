/// Creator portal pipelines list screen — all recent generation jobs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../../core/widgets/status_chip.dart';
import '../../../video_generator/domain/entities/recent_job_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../widgets/admin_bottom_nav.dart';

/// One pipeline job entry in the list.
class _PipelineJob {
  const _PipelineJob({
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

const List<_PipelineJob> _jobs = <_PipelineJob>[
  _PipelineJob(
    icon: Icons.eco_rounded,
    title: 'Science Std 6',
    subtitle: 'The World of Plants',
    status: StatusChipKind.success,
    taskId: 'mock-science-6',
  ),
  _PipelineJob(
    icon: Icons.calculate_rounded,
    title: 'Maths Std 7',
    subtitle: 'Integers',
    status: StatusChipKind.success,
    taskId: 'mock-maths-7',
  ),
  _PipelineJob(
    icon: Icons.translate_rounded,
    title: 'Tamil Std 8',
    subtitle: 'எழுத்து - 1',
    status: StatusChipKind.inProgress,
    taskId: 'mock-tamil-8',
  ),
  _PipelineJob(
    icon: Icons.public_rounded,
    title: 'Social Science Std 6',
    subtitle: 'Our Earth',
    status: StatusChipKind.neutral,
    taskId: 'mock-social-6',
  ),
];

/// Lists all AI pipeline generation jobs.
class AdminPipelinesScreen extends ConsumerWidget {
  /// Creates the admin pipelines screen.
  const AdminPipelinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<RecentJobEntity>> recentJobsAsync = ref.watch(recentJobsProvider);

    final List<_PipelineJob> realJobs = recentJobsAsync.maybeWhen(
      data: (List<RecentJobEntity> jobs) => jobs.map((RecentJobEntity job) {
        final IconData icon = job.subject.toLowerCase().contains('science')
            ? Icons.eco_rounded
            : job.subject.toLowerCase().contains('math')
                ? Icons.calculate_rounded
                : job.subject.toLowerCase().contains('tamil')
                    ? Icons.translate_rounded
                    : Icons.public_rounded;
        final StatusChipKind status = switch (job.status) {
          'COMPLETED' => StatusChipKind.success,
          'PROCESSING' => StatusChipKind.inProgress,
          'FAILED' => StatusChipKind.danger,
          _ => StatusChipKind.neutral,
        };
        return _PipelineJob(
          icon: icon,
          title: '${job.subject} ${job.classLevel}',
          subtitle: job.chapterTitle,
          status: status,
          taskId: job.taskId,
        );
      }).toList(),
      orElse: () => const <_PipelineJob>[],
    );

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Pipelines'),
        automaticallyImplyLeading: false,
        actions: const <Widget>[NotificationBell()],
      ),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.pipeline),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text('All Pipelines', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          DashboardCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                if (realJobs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No pipelines yet. Upload a textbook to create one.'),
                  )
                else
                  for (int i = 0; i < realJobs.length; i++) ...<Widget>[
                  _PipelineJobTile(job: realJobs[i]),
                  if (i < realJobs.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineJobTile extends StatelessWidget {
  const _PipelineJobTile({required this.job});

  final _PipelineJob job;

  @override
  Widget build(BuildContext context) {
    final String statusLabel = switch (job.status) {
      StatusChipKind.success => 'Completed',
      StatusChipKind.inProgress => 'Processing',
      StatusChipKind.neutral => 'Queued',
      StatusChipKind.danger => 'Failed',
    };

    return InkWell(
      onTap: () {
        context.goNamed(
          AppRoute.adminPipeline.routeName,
          pathParameters: <String, String>{'taskId': job.taskId},
        );
      },
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
              child: Icon(job.icon, color: AppColors.primaryBlue, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  Text(
                    job.subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
            StatusChip(label: statusLabel, kind: job.status),
            const SizedBox(width: 8),
            Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }
}
