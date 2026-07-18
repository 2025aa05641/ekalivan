/// Riverpod async state for requesting and observing a video generation task.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/video_remote_data_source.dart';
import '../../data/repositories/video_repository_impl.dart';
import '../../domain/entities/recent_job_entity.dart';
import '../../domain/entities/video_job_entity.dart';
import '../../domain/entities/video_status_update_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/value_objects/video_generation_request_params.dart';

/// Provides the shared network client for data-layer dependencies.
final Provider<ApiClient> apiClientProvider = Provider<ApiClient>((Ref ref) => ApiClient());

/// Provides the repository contract to presentation code through dependency injection.
final Provider<IVideoRepository> videoRepositoryProvider = Provider<IVideoRepository>(
  (Ref ref) => VideoRepositoryImpl(VideoRemoteDataSource(ref.watch(apiClientProvider))),
);

/// Owns the async request lifecycle for accepting a new generation job.
final AsyncNotifierProvider<VideoGenerationNotifier, VideoJobEntity?> videoGenerationProvider =
    AsyncNotifierProvider<VideoGenerationNotifier, VideoJobEntity?>(VideoGenerationNotifier.new);

/// Fetches the list of recent jobs from the server.
final AutoDisposeFutureProvider<List<RecentJobEntity>> recentJobsProvider =
    FutureProvider.autoDispose<List<RecentJobEntity>>(
  (Ref ref) => ref.watch(videoRepositoryProvider).getRecentJobs(),
);

/// Converts a user action into observed asynchronous generation state.
class VideoGenerationNotifier extends AsyncNotifier<VideoJobEntity?> {
  @override
  VideoJobEntity? build() => null;

  /// Starts an accepted-job request and exposes its result or failure as AsyncValue.
  Future<void> request(VideoGenerationRequestParams params) async {
    state = const AsyncLoading<VideoJobEntity?>();
    state = await AsyncValue.guard(
      () => ref.read(videoRepositoryProvider).requestVideoGeneration(params: params),
    );
  }
}

/// Observes a single job's status until it reaches a terminal state.
final StreamProviderFamily<VideoStatusUpdateEntity, String> videoProgressProvider =
    StreamProvider.family<VideoStatusUpdateEntity, String>(
  (Ref ref, String taskId) => ref.watch(videoRepositoryProvider).watchGenerationProgress(taskId: taskId),
);

/// Loads previously completed videos cached for offline playback.
///
/// `autoDispose` so the list is re-read from the cache every time the My
/// Videos screen is (re)entered, rather than reusing a stale result from
/// before the most recently completed job was cached.
final AutoDisposeFutureProvider<List<VideoJobEntity>> myVideosProvider =
    FutureProvider.autoDispose<List<VideoJobEntity>>(
  (Ref ref) => ref.watch(videoRepositoryProvider).getOfflineCachedVideos(),
);
