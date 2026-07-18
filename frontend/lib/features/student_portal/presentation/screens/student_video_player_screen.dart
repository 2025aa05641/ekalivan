/// Student portal video player screen — streams a lesson video from the backend.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../../../video_generator/presentation/widgets/video_player_view.dart';
import '../../../video_generator/presentation/widgets/web_video_player.dart';
import '../widgets/student_bottom_nav.dart';

/// One-shot future provider that fetches a completed job's status for video
/// playback without subscribing to the continuous polling stream.
final AutoDisposeFutureProviderFamily<VideoStatusUpdateEntity, String>
    _studentJobStatusProvider =
    FutureProvider.autoDispose.family<VideoStatusUpdateEntity, String>(
  (Ref ref, String taskId) async {
    return ref
        .watch(videoRepositoryProvider)
        .watchGenerationProgress(taskId: taskId)
        .first;
  },
);

/// Renders the AI-generated lesson video for a student to watch.
class StudentVideoPlayerScreen extends ConsumerWidget {
  /// Creates the student video player for [taskId].
  const StudentVideoPlayerScreen({super.key, required this.taskId});

  /// Job identifier of the COMPLETED video to watch.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> statusAsync =
        ref.watch(_studentJobStatusProvider(taskId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.studentMedium.routeName);
            }
          },
        ),
        title: const Text('Lesson Video'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Switch Role',
            onPressed: () => context.goNamed(AppRoute.roleSelect.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Student Home',
            onPressed: () => context.goNamed(AppRoute.studentSplash.routeName),
          ),
        ],
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: SafeArea(
        child: statusAsync.when(
          data: (VideoStatusUpdateEntity update) {
            if (update.status != 'COMPLETED' || update.videoUrl == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.hourglass_top_rounded,
                          size: 56, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'This lesson video is not ready yet.\nPlease check back soon!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(_studentJobStatusProvider(taskId)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final String rawUrl = update.videoUrl!;
            final String baseUrl = ref.read(apiClientProvider).baseUrl.replaceAll(RegExp(r'/$'), '');
            final String safeRawUrl = rawUrl.replaceFirst(RegExp(r'^/'), '');
            final String videoUrl = rawUrl.startsWith('http')
                ? rawUrl
                : '$baseUrl/$safeRawUrl';

            return _StudentVideoBody(videoUrl: videoUrl, taskId: taskId);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: AccessibleErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(_studentJobStatusProvider(taskId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentVideoBody extends StatelessWidget {
  const _StudentVideoBody({required this.videoUrl, required this.taskId});

  final String videoUrl;
  final String taskId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: <Widget>[
        // Success header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.play_lesson_rounded, color: AppColors.success, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI-generated lesson video — tap to play',
                  style: TextStyle(color: AppColors.success, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Video player
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: kIsWeb
                ? WebVideoPlayer(videoUrl: videoUrl)
                : VideoPlayerView(videoUrl: videoUrl),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // Info card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.smart_display_rounded,
                        color: AppColors.primaryBlue, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'AI Lesson Video',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'Generated by Ekalivan AI',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.studentMedium.routeName);
            }
          },
          icon: const Icon(Icons.arrow_back_rounded),
          label: const Text('Back to Chapters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}
