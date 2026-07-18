/// Creator portal screen shown once the AI pipeline finishes.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../video_generator/data/datasources/local_video_cache.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../../../video_generator/presentation/widgets/video_player_view.dart';
import '../../../video_generator/presentation/widgets/web_video_player.dart';

/// Family provider: polls job status exactly once (no continuous stream) so
/// the completed-video screen renders the result immediately without re-looping.
final AutoDisposeFutureProviderFamily<VideoStatusUpdateEntity, String>
    _jobStatusOnceProvider =
    FutureProvider.autoDispose.family<VideoStatusUpdateEntity, String>(
  (Ref ref, String taskId) =>
      ref.watch(videoRepositoryProvider).watchGenerationProgress(taskId: taskId).first,
);

/// Celebrates a finished render and offers to preview or publish it.
class PipelineCompleteScreen extends ConsumerWidget {
  /// Creates the pipeline-completed screen for [taskId].
  const PipelineCompleteScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> statusAsync =
        ref.watch(_jobStatusOnceProvider(taskId));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.adminDashboard.routeName);
            }
          },
        ),
        title: const Text('Pipeline Completed!'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Admin Home',
            onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: statusAsync.when(
          data: (VideoStatusUpdateEntity update) =>
              _CompleteBody(taskId: taskId, update: update),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AccessibleErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(_jobStatusOnceProvider(taskId)),
            ),
          ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('Published for students!'),
          ],
        ),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If pipeline hasn't completed yet, poll again after 3s and show spinner.
    if (widget.update.status != 'COMPLETED') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Pipeline is still running (${widget.update.status})…',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Build the absolute video URL.
    final String? rawUrl = widget.update.videoUrl;
    if (rawUrl == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AccessibleErrorWidget(
          message: 'Video URL is not yet available. The pipeline may still be publishing.',
        ),
      );
    }

    final String baseUrl = ref.read(apiClientProvider).baseUrl.replaceAll(RegExp(r'/$'), '');
    final String safeRawUrl = rawUrl.replaceFirst(RegExp(r'^/'), '');
    final String videoUrl = rawUrl.startsWith('http')
        ? rawUrl
        : '$baseUrl/$safeRawUrl';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        // Success celebration header
        Center(
          child: Column(
            children: <Widget>[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.celebration_rounded, color: AppColors.success, size: 40),
              ),
              const SizedBox(height: 14),
              Text(
                'Video Generated Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Detail card
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(
            children: <Widget>[
              _DetailRow(label: 'Task ID', value: widget.taskId),
              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
              _DetailRow(label: 'Status', value: 'COMPLETED ✓'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Video player
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: kIsWeb
                ? WebVideoPlayer(videoUrl: videoUrl)
                : VideoPlayerView(videoUrl: videoUrl),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Video URL hint on web
        if (kIsWeb)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SelectableText(
              videoUrl,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
                fontFamily: 'monospace',
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Back to Pipelines',
          onPressed: () => context.goNamed(AppRoute.adminPipelines.routeName),
        ),
        const SizedBox(height: AppSpacing.sm),
        PrimaryButton(
          label: _published ? 'Published ✓' : 'Publish for Students',
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
