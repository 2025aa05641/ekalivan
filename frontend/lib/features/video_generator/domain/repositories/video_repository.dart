/// Repository contract for generation and offline playback support.
import '../entities/video_job_entity.dart';
import '../entities/video_status_update_entity.dart';
import '../value_objects/video_generation_request_params.dart';

/// Keeps API and persistence details outside domain and presentation layers.
abstract interface class IVideoRepository {
  /// Requests creation of a new video job.
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params});

  /// Observes generation progress for an accepted job.
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId});

  /// Returns previously completed video jobs cached for offline access.
  Future<List<VideoJobEntity>> getOfflineCachedVideos();
}
