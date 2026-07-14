/// Creator portal screen showing the 8-step AI pipeline's live progress.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/pipeline_step.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

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

/// Shows the 8-step AI pipeline with each stage's completed/current/pending
/// status.
///
/// UI only (Phase 3): the mock progress below (steps 1-4 completed, step 5
/// running) is replaced with the real job's status in Phase 4.
class PipelineProgressScreen extends StatelessWidget {
  /// Creates the pipeline progress screen.
  const PipelineProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const int currentStepIndex = 4;
    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: const Text('AI Pipeline - Science 6'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text('The World of Plants', style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < pipelineStageNames.length; i++)
            InkWell(
              onTap: i == currentStepIndex ? () => context.goNamed(AppRoute.adminRendering.routeName) : null,
              child: PipelineStep(
                stepNumber: i + 1,
                label: pipelineStageNames[i],
                status: i < currentStepIndex
                    ? PipelineStepStatus.completed
                    : i == currentStepIndex
                        ? PipelineStepStatus.current
                        : PipelineStepStatus.pending,
              ),
            ),
        ],
      ),
    );
  }
}
