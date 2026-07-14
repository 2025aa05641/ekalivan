/// Persists completed video job summaries to local device/browser storage.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/video_job_entity.dart';

const String _cacheKey = 'cached_completed_videos';

/// Wraps SharedPreferences to store and retrieve completed video summaries,
/// so a previously generated video can be revisited without a network call.
class LocalVideoCache {
  /// Creates the cache with an injectable SharedPreferences instance factory.
  const LocalVideoCache({Future<SharedPreferences> Function()? preferencesFactory})
      : _preferencesFactory = preferencesFactory ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferencesFactory;

  /// Records or updates one completed job's cached summary.
  ///
  /// A job already cached under the same [VideoJobEntity.taskId] is replaced
  /// rather than duplicated.
  Future<void> saveCompletedJob(VideoJobEntity job) async {
    final SharedPreferences preferences = await _preferencesFactory();
    final List<VideoJobEntity> existing = await _readAll(preferences);
    final List<VideoJobEntity> updated = <VideoJobEntity>[
      job,
      ...existing.where((VideoJobEntity cached) => cached.taskId != job.taskId),
    ];
    await preferences.setString(_cacheKey, jsonEncode(updated.map(_toJson).toList()));
  }

  /// Returns all cached completed job summaries, most recently cached first.
  Future<List<VideoJobEntity>> getAll() async => _readAll(await _preferencesFactory());

  Future<List<VideoJobEntity>> _readAll(SharedPreferences preferences) async {
    final String? raw = preferences.getString(_cacheKey);
    if (raw == null) {
      return const <VideoJobEntity>[];
    }
    final List<Object?> decoded = jsonDecode(raw) as List<Object?>;
    return decoded.map((Object? entry) => _fromJson(entry! as Map<String, Object?>)).toList();
  }

  Map<String, Object?> _toJson(VideoJobEntity job) =>
      <String, Object?>{'taskId': job.taskId, 'status': job.status, 'videoUrl': job.videoUrl};

  VideoJobEntity _fromJson(Map<String, Object?> json) => VideoJobEntity(
        taskId: json['taskId']! as String,
        status: json['status']! as String,
        videoUrl: json['videoUrl'] as String?,
      );
}
