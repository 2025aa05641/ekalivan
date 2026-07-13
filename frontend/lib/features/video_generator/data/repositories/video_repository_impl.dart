/// Repository implementation combining remote data with future local caching.
import '../../domain/entities/video_job_entity.dart';
import '../../domain/entities/video_status_update_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/value_objects/video_generation_request_params.dart';
import '../datasources/video_remote_data_source.dart';

/// Implements the domain contract without exposing Dio to presentation code.
class VideoRepositoryImpl implements IVideoRepository {
  /// Creates the repository with its remote source dependency.
  const VideoRepositoryImpl(this._remoteDataSource);

  final VideoRemoteDataSource _remoteDataSource;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    return (await _remoteDataSource.requestGeneration(params)).toEntity();
  }

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) {
    return const Stream<VideoStatusUpdateEntity>.empty();
  }
}
