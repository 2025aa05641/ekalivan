/// Creator portal screen shown once the AI pipeline finishes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../video_generator/data/datasources/local_video_cache.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../../../video_generator/presentation/widgets/video_player_view.dart';

/// Celebrates a finished render and offers to preview or publish it.
///
/// "Publish for Students" writes the job to the same local cache the
/// Student portal's "My Videos" screen reads from — there is no separate
/// publish/visibility flag in the backend; a completed job is already
/// servable.
class PipelineCompleteScreen extends ConsumerWidget {
  /// Creates the pipeline-completed screen for [taskId].
  const PipelineCompleteScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: const Text('Pipeline Completed!'),
      ),
      body: SafeArea(
        child: progress.when(
          data: (VideoStatusUpdateEntity update) => _CompleteBody(taskId: taskId, update: update),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) =>
              Padding(padding: const EdgeInsets.all(AppSpacing.md), child: AccessibleErrorWidget(message: error.toString())),
        ),
      ),
    );
  }
}

class _CompleteBody extends ConsumerStatefulWidget {
  const _CompleteBody({required this.taskId, required this.update});

  final String taskId;
  final VideoStatusUpdateEntity update;

  @override
  ConsumerState<_CompleteBody> createState() => _CompleteBodyState();
}

class _CompleteBodyState extends ConsumerState<_CompleteBody> {
  bool _published = false;

  Future<void> _publish() async {
    final String? videoUrl = widget.update.videoUrl;
    if (videoUrl == null) {
      return;
    }
    await const LocalVideoCache().saveCompletedJob(
      VideoJobEntity(taskId: widget.taskId, status: 'COMPLETED', videoUrl: videoUrl),
    );
    if (!mounted) {
      return;
    }
    setState(() => _published = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Published for students.')));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.update.status != 'COMPLETED' || widget.update.videoUrl == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AccessibleErrorWidget(message: 'This video has not finished rendering yet.'),
      );
    }
    final String videoUrl = '${ref.watch(apiClientProvider).baseUrl}${widget.update.videoUrl}';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        const Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.success,
            child: Icon(Icons.celebration_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Center(
          child: Text(
            'Video Generated Successfully',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const DashboardCard(
          child: Column(
            children: <Widget>[
              _DetailRow(label: 'Book', value: 'Science Std 6'),
              _DetailRow(label: 'Chapter', value: 'The World of Plants'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AspectRatio(aspectRatio: 16 / 9, child: VideoPlayerView(videoUrl: videoUrl)),
        const SizedBox(height: AppSpacing.lg),
        SecondaryButton(label: 'Preview Video', onPressed: () {}),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: _published ? 'Published' : 'Publish for Students',
          onPressed: _published ? null : _publish,
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

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
