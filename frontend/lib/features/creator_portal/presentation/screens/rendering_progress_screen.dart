/// Creator portal screen for the pipeline's Video Rendering step in detail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';

/// Detail view for the pipeline's "Video Rendering" step, showing the job's
/// real progress percentage and plain-language current stage.
class RenderingProgressScreen extends ConsumerWidget {
  /// Creates the rendering progress screen for [taskId].
  const RenderingProgressScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () =>
              context.goNamed(AppRoute.adminPipeline.routeName, pathParameters: <String, String>{'taskId': taskId}),
        ),
        title: const Text('Pipeline - Step 5'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            child: const Text(
              'Video Rendering',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
        ),
      ),
      body: progress.when(
        data: (VideoStatusUpdateEntity update) => _RenderingBody(taskId: taskId, update: update),
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

class _RenderingBody extends StatelessWidget {
  const _RenderingBody({required this.taskId, required this.update});

  final String taskId;
  final VideoStatusUpdateEntity update;

  @override
  Widget build(BuildContext context) {
    if (update.status == 'FAILED') {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: AccessibleErrorWidget(message: update.errorMessage ?? 'The video could not be rendered.'),
      );
    }

    // Simulated stats for mockup
    const String estimatedTime = '00:03:45';
    const String currentTopic = 'Photosynthesis';
    const String progressText = '12/18 Topics';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        // Video rendering card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: <Widget>[
              // Camera icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.movie_creation_rounded, size: 36, color: AppColors.primaryBlue),
              ),
              const SizedBox(height: 16),
              Text(
                'Rendering Video',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                update.currentNode,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              // Progress bar
              Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: update.progress / 100,
                    child: Container(
                      height: 10,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryBlue, AppColors.primaryPurple],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${update.progress.round()}%',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryBlue,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 16),
              _StatRow(label: 'Estimated Time Remaining', value: estimatedTime),
              const SizedBox(height: 8),
              _StatRow(label: 'Current Topic', value: currentTopic),
              const SizedBox(height: 8),
              _StatRow(label: 'Progress', value: progressText),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Notification banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.primaryBlue, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You will be notified once the video is ready.',
                  style: TextStyle(color: AppColors.primaryBlue, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
          label: update.status == 'COMPLETED' ? 'View Result' : 'Check Again',
          onPressed: () => context.goNamed(
            update.status == 'COMPLETED' ? AppRoute.adminComplete.routeName : AppRoute.adminPipeline.routeName,
            pathParameters: <String, String>{'taskId': taskId},
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
