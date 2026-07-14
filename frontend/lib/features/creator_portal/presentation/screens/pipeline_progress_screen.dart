/// Creator portal screen showing the 8-step AI pipeline's live progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pipeline_step.dart';
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
///
/// The backend only reports coarse status (queued/processing/completed/
/// failed), not which of the 8 LangGraph stages is currently running, so
/// each step's completed/current/pending state is interpolated from the
/// job's overall progress percentage rather than tracked exactly.
class PipelineProgressScreen extends ConsumerWidget {
  /// Creates the pipeline progress screen for [taskId].
  const PipelineProgressScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: const Text('AI Pipeline - Science 6'),
      ),
      body: progress.when(
        data: (VideoStatusUpdateEntity update) => _PipelineStepList(taskId: taskId, update: update),
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
  const _PipelineStepList({required this.taskId, required this.update});

  final String taskId;
  final VideoStatusUpdateEntity update;

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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text('The World of Plants', style: TextStyle(color: Colors.grey)),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < pipelineStageNames.length; i++)
          InkWell(
            onTap: update.status == 'COMPLETED'
                ? () => context.goNamed(AppRoute.adminComplete.routeName, pathParameters: <String, String>{'taskId': taskId})
                : i == completedSteps
                    ? () => context.goNamed(
                          AppRoute.adminRendering.routeName,
                          pathParameters: <String, String>{'taskId': taskId},
                        )
                    : null,
            child: PipelineStep(
              stepNumber: i + 1,
              label: pipelineStageNames[i],
              status: update.status == 'COMPLETED'
                  ? PipelineStepStatus.completed
                  : i < completedSteps
                      ? PipelineStepStatus.completed
                      : i == completedSteps
                          ? PipelineStepStatus.current
                          : PipelineStepStatus.pending,
            ),
          ),
      ],
    );
  }
}
