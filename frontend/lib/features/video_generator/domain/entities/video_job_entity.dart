/// Domain representation of an accepted video generation job.
library;

/// Immutable, technology-independent view of an accepted generation job.
class VideoJobEntity {
  /// Creates an immutable video job entity.
  const VideoJobEntity({required this.taskId, required this.status, this.estimatedTimeSeconds, this.videoUrl});

  /// Server-generated asynchronous task identifier.
  final String taskId;

  /// Current task lifecycle state.
  final String status;

  /// Optional server estimate used to set student expectations.
  ///
  /// The backend does not currently compute this; it is nullable so the
  /// entity stays correct if that changes rather than assuming a value.
  final double? estimatedTimeSeconds;

  /// Servable video URL, present once a job has reached `COMPLETED` and been
  /// written to the offline cache.
  final String? videoUrl;
}
