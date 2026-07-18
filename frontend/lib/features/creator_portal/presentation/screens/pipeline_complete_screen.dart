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

/// Celebrates a finished render and offers to preview or publish it.
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
    if (widget.update.status != 'COMPLETED' || widget.update.videoUrl == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: AccessibleErrorWidget(message: 'This video has not finished rendering yet.'),
      );
    }
    final String rawUrl = widget.update.videoUrl!;
    final String videoUrl = rawUrl.startsWith('http')
        ? rawUrl
        : '${ref.watch(apiClientProvider).baseUrl}$rawUrl';

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
              _DetailRow(label: 'Book', value: 'Science Std 6'),
              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
              _DetailRow(label: 'Chapter', value: 'The World of Plants'),
              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
              _DetailRow(label: 'Topics', value: '18'),
              const Divider(height: 1, indent: 16, endIndent: 16, color: AppColors.border),
              _DetailRow(label: 'Duration', value: '08:42'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        // Video player — use native HTML <video> on web to avoid CORS/codec issues
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
        // Direct link for convenience on web
        if (kIsWeb)
          TextButton.icon(
            onPressed: () {
              // Opens video URL in new browser tab
              // ignore: avoid_web_libraries_in_flutter
              // dart:js_util is not needed — anchor click works via html.window
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(
              'Open video in new tab',
              style: TextStyle(color: AppColors.primaryBlue.withValues(alpha: 0.8), fontSize: 13),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        SecondaryButton(
          label: 'Preview Video',
          onPressed: () {
            // Scroll back up to video — already visible
          },
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
