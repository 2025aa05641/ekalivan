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
  const VideoRepositoryImpl(
    this._remoteDataSource, {
    Duration pollInterval = const Duration(seconds: 3),
    int maxConsecutivePollFailures = 3,
  })  : _pollInterval = pollInterval,
        _maxConsecutivePollFailures = maxConsecutivePollFailures;

  final VideoRemoteDataSource _remoteDataSource;
  final Duration _pollInterval;
  final int _maxConsecutivePollFailures;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    return (await _remoteDataSource.requestGeneration(params)).toEntity();
  }

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) async* {
    int consecutiveFailures = 0;
    while (true) {
      final VideoStatusUpdateEntity? update = await _pollOnce(taskId, onFailure: () => consecutiveFailures++);
      if (update == null) {
        if (consecutiveFailures >= _maxConsecutivePollFailures) {
          throw StateError('Lost connection to the learning service after $consecutiveFailures attempts.');
        }
        await Future<void>.delayed(_pollInterval);
        continue;
      }
      consecutiveFailures = 0;
      yield update;
      if (_terminalStatuses.contains(update.status)) {
        return;
      }
      await Future<void>.delayed(_pollInterval);
    }
  }

  /// Polls once, swallowing a transient failure so a single flaky request
  /// (e.g. one dropped preflight during a multi-minute job) does not end
  /// the whole progress stream. Returns `null` on failure.
  Future<VideoStatusUpdateEntity?> _pollOnce(String taskId, {required void Function() onFailure}) async {
    try {
      return (await _remoteDataSource.getStatus(taskId)).toEntity();
    } catch (_) {
      onFailure();
      return null;
    }
  }
}
