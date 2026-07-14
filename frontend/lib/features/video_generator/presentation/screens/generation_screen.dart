/// Shows live generation progress and, once ready, the finished lesson video.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/accessible_text.dart';
import '../../../../core/widgets/async_progress_bar.dart';
import '../../domain/entities/video_status_update_entity.dart';
import '../providers/video_generation_provider.dart';
import '../widgets/video_player_view.dart';

/// Displays live progress for one accepted job, then its finished video.
class GenerationScreen extends ConsumerWidget {
  /// Creates the generation screen for the job identified by [taskId].
  const GenerationScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    return Scaffold(
      appBar: AppBar(title: const Text('Your Video')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: progress.when(
            data: (VideoStatusUpdateEntity update) =>
                _GenerationBody(update: update, baseUrl: ref.watch(apiClientProvider).baseUrl),
            loading: () => const AsyncProgressBar(progress: 0, label: 'Starting…'),
            error: (Object error, StackTrace stackTrace) => AccessibleErrorWidget(
              message: error.toString(),
              onRetry: () => ref.invalidate(videoProgressProvider(taskId)),
            ),
          ),
        ),
      ),
    );
  }
}

class _GenerationBody extends StatelessWidget {
  const _GenerationBody({required this.update, required this.baseUrl});

  final VideoStatusUpdateEntity update;
  final String baseUrl;

  @override
  Widget build(BuildContext context) {
    final String? videoUrl = update.videoUrl;
    if (update.status == 'COMPLETED' && videoUrl != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AccessibleText('Your video is ready!', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 16),
          VideoPlayerView(videoUrl: '$baseUrl$videoUrl'),
        ],
      );
    }
    if (update.status == 'FAILED') {
      return AccessibleErrorWidget(message: update.errorMessage ?? 'Something went wrong.');
    }
    return AsyncProgressBar(progress: update.progress, label: update.currentNode);
  }
}
