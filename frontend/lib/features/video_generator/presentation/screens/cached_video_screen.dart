/// Replays one previously generated video from the offline cache.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter/foundation.dart';

import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/accessible_text.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/video_job_entity.dart';
import '../providers/video_generation_provider.dart';
import '../widgets/video_player_view.dart';
import '../widgets/web_video_player.dart';

/// Plays back [job]'s cached video directly, without polling the backend
/// for status: the job already reached `COMPLETED` when it was cached.
class CachedVideoScreen extends ConsumerWidget {
  /// Creates the cached video screen for [job].
  const CachedVideoScreen({super.key, required this.job});

  /// Cached job summary, including its playable [VideoJobEntity.videoUrl].
  final VideoJobEntity job;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? rawUrl = job.videoUrl;
    return Scaffold(
      appBar: AppBar(title: const Text('Your Video')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: rawUrl == null
              ? const AccessibleErrorWidget(message: 'This saved video is no longer available.')
              : _CachedVideoBody(
                  videoUrl: rawUrl.startsWith('http') 
                      ? rawUrl 
                      : '${ref.watch(apiClientProvider).baseUrl}$rawUrl'
                ),
        ),
      ),
    );
  }
}

class _CachedVideoBody extends StatelessWidget {
  const _CachedVideoBody({required this.videoUrl});

  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Center(
            child: kIsWeb 
                ? WebVideoPlayer(videoUrl: videoUrl)
                : VideoPlayerView(videoUrl: videoUrl),
          ),
        ),
      ],
    );
  }
}
