/// Creator portal screen for the pipeline's Video Rendering step in detail.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const Text('Video Rendering', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: AppSpacing.lg),
        DashboardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Column(
                  children: <Widget>[
                    const Icon(Icons.movie_creation_rounded, size: 56, color: AppColors.primaryBlue),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Rendering Video', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(update.currentNode, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: LinearProgressIndicator(
                  value: update.progress / 100,
                  minHeight: 8,
                  backgroundColor: AppColors.border,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _StatRow(label: 'Progress', value: '${update.progress.round()}%'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'You will be notified once the video is ready.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
