/// Domain representation of an observed generation progress update.
class VideoStatusUpdateEntity {
  /// Creates an immutable status event.
  const VideoStatusUpdateEntity({required this.progress, required this.currentNode, required this.status});

  /// Completion percentage.
  final double progress;

  /// Backend graph node or queued status.
  final String currentNode;

  /// Current lifecycle state.
  final String status;
}
