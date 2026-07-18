/// Creator portal published videos screen — shows videos saved via "Publish for Students".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../video_generator/domain/entities/recent_job_entity.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../widgets/admin_bottom_nav.dart';

/// Displays the library of videos published via the pipeline-complete screen
/// as well as any COMPLETED jobs in the backend (merged and de-duplicated).
class AdminVideosScreen extends ConsumerWidget {
  /// Creates the admin videos screen.
  const AdminVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VideoJobEntity>> cachedAsync = ref.watch(myVideosProvider);
    final AsyncValue<List<RecentJobEntity>> recentAsync = ref.watch(recentJobsProvider);

    // Merge local cache with backend COMPLETED jobs.
    // Show loading only if both are still loading; prefer to show partial data.
    final bool isLoading = cachedAsync.isLoading && recentAsync.isLoading;
    if (isLoading) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Published Videos'),
          automaticallyImplyLeading: false,
          actions: const <Widget>[NotificationBell()],
        ),
        bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.videos),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Build a combined list. Local-cache entries take priority (they have a real videoUrl).
    final Map<String, VideoJobEntity> videoMap = <String, VideoJobEntity>{};
    for (final VideoJobEntity v in cachedAsync.valueOrNull ?? <VideoJobEntity>[]) {
      videoMap[v.taskId] = v;
    }
    // Supplement with backend COMPLETED jobs not yet in local cache.
    for (final RecentJobEntity j in recentAsync.valueOrNull ?? <RecentJobEntity>[]) {
      if (j.status == 'COMPLETED' && !videoMap.containsKey(j.taskId)) {
        videoMap[j.taskId] = VideoJobEntity(
          taskId: j.taskId,
          status: j.status,
          // videoUrl will be resolved when navigating to the complete screen.
          videoUrl: null,
        );
      }
    }
    final List<VideoJobEntity> allVideos = videoMap.values.toList();

    return AppScaffold(
      appBar: AppBar(
        title: const Text('Published Videos'),
        automaticallyImplyLeading: false,
        actions: const <Widget>[NotificationBell()],
      ),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.videos),
      body: allVideos.isEmpty
          ? _EmptyState()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: <Widget>[
                // Header stats
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7E3FF2), Color(0xFFA855F7)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.video_library_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '${allVideos.length} Video${allVideos.length == 1 ? '' : 's'}',
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'published for students',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text('All Published Videos', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppSpacing.sm),
                for (final VideoJobEntity video in allVideos) ...<Widget>[
                  _VideoCard(video: video),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.video_library_rounded, size: 72, color: AppColors.primaryPurple.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'No Published Videos Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete a pipeline and tap "Publish for Students" to see videos here.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.goNamed(AppRoute.adminPipelines.routeName),
            icon: const Icon(Icons.timeline_rounded),
            label: const Text('View Pipelines'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryPurple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final VideoJobEntity video;

  @override
  Widget build(BuildContext context) {
    final String displayTitle = video.taskId.replaceAll('-', ' ').toUpperCase();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () {
          // Navigate to complete screen to preview/manage this video
          context.goNamed(
            AppRoute.adminComplete.routeName,
            pathParameters: <String, String>{'taskId': video.taskId},
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              // Thumbnail placeholder
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 70,
                  height: 50,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1B5E20), Color(0xFF0D3B73)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.play_circle_filled_rounded, color: Colors.white70, size: 28),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const <Widget>[
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 11),
                              SizedBox(width: 3),
                              Text(
                                'Published',
                                style: TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
