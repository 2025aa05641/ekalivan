/// Lists previously generated videos cached for offline playback.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/accessible_text.dart';
import '../../domain/entities/video_job_entity.dart';
import '../providers/router_provider.dart';
import '../providers/video_generation_provider.dart';

/// Shows videos saved locally after a prior successful generation, so a
/// student can rewatch a lesson without regenerating or reconnecting.
class MyVideosScreen extends ConsumerWidget {
  /// Creates the my-videos screen.
  const MyVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<VideoJobEntity>> cachedVideos = ref.watch(myVideosProvider);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('My Videos'),
      ),
      body: SafeArea(
        child: cachedVideos.when(
          data: (List<VideoJobEntity> videos) => _CachedVideoList(videos: videos),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stackTrace) => Padding(
            padding: const EdgeInsets.all(24),
            child: AccessibleErrorWidget(
              message: 'Your saved videos could not be loaded.',
              onRetry: () => ref.invalidate(myVideosProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _CachedVideoList extends StatelessWidget {
  const _CachedVideoList({required this.videos});

  final List<VideoJobEntity> videos;

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AccessibleText(
          "You haven't watched any videos yet. Generate one from the home screen to see it here.",
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: videos.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) => _CachedVideoTile(video: videos[index]),
    );
  }
}

class _CachedVideoTile extends StatelessWidget {
  const _CachedVideoTile({required this.video});

  final VideoJobEntity video;

  @override
  Widget build(BuildContext context) {
    final String shortId = video.taskId.length > 8 ? video.taskId.substring(0, 8) : video.taskId;
    return Semantics(
      button: true,
      label: 'Watch saved video $shortId again',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(Icons.play_circle_fill, size: 36),
          title: AccessibleText('Saved video $shortId'),
          subtitle: const AccessibleText('Tap to watch again'),
          onTap: () => context.pushNamed(AppRoute.cachedVideo.routeName, extra: video),
        ),
      ),
    );
  }
}
