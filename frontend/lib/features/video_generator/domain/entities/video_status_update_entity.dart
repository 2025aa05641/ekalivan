/// Domain representation of an observed generation progress update.
library;

/// Immutable, technology-independent view of one generation progress update.
class VideoStatusUpdateEntity {
  /// Creates an immutable status event.
  const VideoStatusUpdateEntity({
    required this.progress,
    required this.currentNode,
    required this.status,
    this.videoUrl,
    this.errorMessage,
  });

  /// Completion percentage.
  final double progress;

  /// Plain-language current stage, shown in place of a technical status code.
  final String currentNode;

  /// Current lifecycle state (`QUEUED`, `PROCESSING`, `COMPLETED`, or `FAILED`).
  final String status;

  /// Servable video URL, present once [status] is `COMPLETED`.
  final String? videoUrl;

  /// Safe failure description, present once [status] is `FAILED`.
  final String? errorMessage;
}
