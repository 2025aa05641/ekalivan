/// Creator portal screen showing the 8-step AI pipeline's live progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/domain/entities/recent_job_entity.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';

/// One named stage in the 8-step AI content-generation pipeline.
const List<String> pipelineStageNames = <String>[
  'Lesson Planner',
  'Teacher',
  'Storyboard',
  'Narration (TTS)',
  'Video Rendering',
  'Publishing',
  'Quality Check',
  'Final Publish',
];

/// Shows the 8-step AI pipeline for the job identified by [taskId].
class PipelineProgressScreen extends ConsumerWidget {
  /// Creates the pipeline progress screen for [taskId].
  const PipelineProgressScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    final AsyncValue<List<RecentJobEntity>> recentJobsAsync = ref.watch(recentJobsProvider);

    final RecentJobEntity? realJob = recentJobsAsync.maybeWhen(
      data: (List<RecentJobEntity> jobs) {
        try {
          return jobs.firstWhere((RecentJobEntity j) => j.taskId == taskId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    final String title = realJob != null
        ? 'AI Pipeline - ${realJob.subject} ${realJob.classLevel}'
        : switch (taskId) {
            'mock-science-6' => 'AI Pipeline - Science Std 6',
            'mock-maths-7' => 'AI Pipeline - Maths Std 7',
            'mock-tamil-8' => 'AI Pipeline - Tamil Std 8',
            'mock-social-6' => 'AI Pipeline - Social Science Std 6',
            _ => 'AI Pipeline',
          };

    final String subtitle = realJob != null
        ? realJob.chapterTitle
        : switch (taskId) {
            'mock-science-6' => 'The World of Plants',
            'mock-maths-7' => 'Integers',
            'mock-tamil-8' => 'எழுத்து - 1',
            'mock-social-6' => 'Our Earth',
            _ => 'Generating video...',
          };

    final IconData icon = realJob != null
        ? (realJob.subject.toLowerCase().contains('science')
            ? Icons.eco_rounded
            : realJob.subject.toLowerCase().contains('math')
                ? Icons.calculate_rounded
                : realJob.subject.toLowerCase().contains('tamil')
                    ? Icons.translate_rounded
                    : Icons.public_rounded)
        : switch (taskId) {
            'mock-science-6' => Icons.eco_rounded,
            'mock-maths-7' => Icons.calculate_rounded,
            'mock-tamil-8' => Icons.translate_rounded,
            _ => Icons.public_rounded,
          };

    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: Text(title),
      ),
      body: progress.when(
        data: (VideoStatusUpdateEntity update) => _PipelineStepList(
          taskId: taskId,
          update: update,
          subtitle: subtitle,
          icon: icon,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AccessibleErrorWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(videoProgressProvider(taskId)),
          ),
        ),
      ),
    );
  }
}

class _PipelineStepList extends StatelessWidget {
  const _PipelineStepList({
    required this.taskId,
    required this.update,
    required this.subtitle,
    required this.icon,
  });

  final String taskId;
  final VideoStatusUpdateEntity update;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    if (update.status == 'FAILED') {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AccessibleErrorWidget(message: update.errorMessage ?? 'The pipeline could not finish.'),
      );
    }
    final int completedSteps = (update.progress / 100 * pipelineStageNames.length).floor().clamp(
          0,
          pipelineStageNames.length,
        );
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      children: <Widget>[
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
        ),
        // Pipeline steps
        for (int i = 0; i < pipelineStageNames.length; i++)
          _PipelineStepTile(
            stepNumber: i + 1,
            label: pipelineStageNames[i],
            status: update.status == 'COMPLETED'
                ? _StepStatus.completed
                : i < completedSteps
                    ? _StepStatus.completed
                    : i == completedSteps
                        ? _StepStatus.current
                        : _StepStatus.pending,
            subtitle: update.status == 'COMPLETED'
                ? 'Completed'
                : i < completedSteps
                    ? 'Completed'
                    : i == completedSteps
                        ? 'Processing'
                        : 'Queued',
            onTap: update.status == 'COMPLETED'
                ? () => context.goNamed(AppRoute.adminComplete.routeName, pathParameters: <String, String>{'taskId': taskId})
                : i == completedSteps
                    ? () => context.goNamed(
                          AppRoute.adminRendering.routeName,
                          pathParameters: <String, String>{'taskId': taskId},
                        )
                    : null,
          ),
      ],
    );
  }
}

enum _StepStatus { completed, current, pending }

class _PipelineStepTile extends StatelessWidget {
  const _PipelineStepTile({
    required this.stepNumber,
    required this.label,
    required this.status,
    required this.subtitle,
    this.onTap,
  });

  final int stepNumber;
  final String label;
  final _StepStatus status;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      _StepStatus.completed => AppColors.success,
      _StepStatus.current => AppColors.primaryBlue,
      _StepStatus.pending => Colors.grey.shade400,
    };

    final Widget trailingIndicator = switch (status) {
      _StepStatus.completed => const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
      _StepStatus.current => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
      _StepStatus.pending => Icon(Icons.radio_button_unchecked_rounded, color: color, size: 22),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: status == _StepStatus.current
              ? AppColors.primaryBlue.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == _StepStatus.current ? AppColors.primaryBlue.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: status == _StepStatus.pending ? Colors.grey : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ],
              ),
            ),
            trailingIndicator,
          ],
        ),
      ),
    );
  }
}
