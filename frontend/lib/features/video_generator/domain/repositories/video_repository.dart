/// Repository contract for generation and later offline playback support.
import '../entities/video_job_entity.dart';
import '../entities/video_status_update_entity.dart';
import '../value_objects/video_generation_request_params.dart';

/// Keeps API and persistence details outside domain and presentation layers.
abstract interface class IVideoRepository {
  /// Requests creation of a new video job.
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params});

  /// Observes generation progress for an accepted job.
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId});

  /// Returns downloaded video jobs when the offline cache is added in Sprint 4.
  Future<List<VideoJobEntity>> getOfflineCachedVideos();
}
