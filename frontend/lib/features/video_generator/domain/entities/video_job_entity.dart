/// Domain representation of an accepted video generation job.
class VideoJobEntity {
  /// Creates an immutable video job entity.
  const VideoJobEntity({required this.taskId, required this.status, required this.estimatedTimeSeconds});

  /// Server-generated asynchronous task identifier.
  final String taskId;

  /// Current task lifecycle state.
  final String status;

  /// API estimate used to set student expectations.
  final double estimatedTimeSeconds;
}
