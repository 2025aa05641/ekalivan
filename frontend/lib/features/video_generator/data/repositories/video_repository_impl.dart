/// Repository implementation combining remote data with local offline caching.
library;

import '../../domain/entities/recent_job_entity.dart';
import '../../domain/entities/video_job_entity.dart';
import '../../domain/entities/video_status_update_entity.dart';
import '../../domain/repositories/video_repository.dart';
import '../../domain/value_objects/video_generation_request_params.dart';
import '../datasources/local_video_cache.dart';
import '../datasources/video_remote_data_source.dart';
import '../models/recent_job_model.dart';

const Set<String> _terminalStatuses = <String>{'COMPLETED', 'FAILED'};

/// Implements the domain contract without exposing Dio to presentation code.
class VideoRepositoryImpl implements IVideoRepository {
  /// Creates the repository with its remote source dependency.
  const VideoRepositoryImpl(
    this._remoteDataSource, {
    Duration pollInterval = const Duration(seconds: 3),
    int maxConsecutivePollFailures = 3,
    LocalVideoCache localCache = const LocalVideoCache(),
  })  : _pollInterval = pollInterval,
        _maxConsecutivePollFailures = maxConsecutivePollFailures,
        _localCache = localCache;

  final VideoRemoteDataSource _remoteDataSource;
  final Duration _pollInterval;
  final int _maxConsecutivePollFailures;
  final LocalVideoCache _localCache;

  @override
  Future<String> uploadVideoSource({required List<int> bytes, required String filename}) async {
    return _remoteDataSource.uploadFile(bytes: bytes, filename: filename);
  }

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    return (await _remoteDataSource.requestGeneration(params)).toEntity();
  }

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() => _localCache.getAll();

  @override
  Future<List<RecentJobEntity>> getRecentJobs({int limit = 20}) async {
    final List<RecentJobModel> models = await _remoteDataSource.getRecentJobs(limit: limit);
    return models.map((RecentJobModel m) => m.toEntity()).toList();
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) async* {
    if (taskId.startsWith('mock-')) {
      final String status = switch (taskId) {
        'mock-science-6' || 'mock-maths-7' => 'COMPLETED',
        'mock-tamil-8' => 'PROCESSING',
        _ => 'QUEUED',
      };
      final double progress = switch (taskId) {
        'mock-science-6' || 'mock-maths-7' => 100.0,
        'mock-tamil-8' => 50.0,
        _ => 0.0,
      };
      final String currentNode = switch (taskId) {
        'mock-science-6' || 'mock-maths-7' => 'Final Publish',
        'mock-tamil-8' => 'Narration (TTS)',
        _ => 'Lesson Planner',
      };
      final String? videoUrl = switch (taskId) {
        'mock-science-6' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
        'mock-maths-7' => 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
        _ => null,
      };
      yield VideoStatusUpdateEntity(
        progress: progress,
        currentNode: currentNode,
        status: status,
        videoUrl: videoUrl,
      );
      return;
    }

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
      if (update.status == 'COMPLETED' && update.videoUrl != null) {
        await _localCache.saveCompletedJob(
          VideoJobEntity(taskId: taskId, status: update.status, videoUrl: update.videoUrl),
        );
      }
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
