/// Repository implementation combining remote data with future local caching.
library;

import '../../domain/entities/video_job_entity.dart';
import '../../domain/entities/video_status_update_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/value_objects/video_generation_request_params.dart';
import '../datasources/video_remote_data_source.dart';

const Set<String> _terminalStatuses = <String>{'COMPLETED', 'FAILED'};

/// Implements the domain contract without exposing Dio to presentation code.
class VideoRepositoryImpl implements IVideoRepository {
  /// Creates the repository with its remote source dependency.
  const VideoRepositoryImpl(this._remoteDataSource, {Duration pollInterval = const Duration(seconds: 3)})
      : _pollInterval = pollInterval;

  final VideoRemoteDataSource _remoteDataSource;
  final Duration _pollInterval;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    return (await _remoteDataSource.requestGeneration(params)).toEntity();
  }

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) async* {
    while (true) {
      final VideoStatusUpdateEntity update = (await _remoteDataSource.getStatus(taskId)).toEntity();
      yield update;
      if (_terminalStatuses.contains(update.status)) {
        return;
      }
      await Future<void>.delayed(_pollInterval);
    }
  }
}
