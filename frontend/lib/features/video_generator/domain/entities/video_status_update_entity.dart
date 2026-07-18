/// Domain representation of an observed generation progress update.
library;

/// Immutable, technology-independent view of one generation progress update.
class VideoStatusUpdateEntity {
  /// Creates an immutable status event.
  const VideoStatusUpdateEntity({
    required this.progress,
    required this.currentNode,
    required this.status,
    this.markdownContent,
    this.sections,
    this.storyboardBeats,
    this.narratedBeats,
    this.videoUrl,
    this.errorMessage,
  });

  /// Completion percentage (0–100).
  final double progress;

  /// Plain-language current stage, shown in place of a technical status code.
  final String currentNode;

  /// Current lifecycle state (`QUEUED`, `PROCESSING`, `COMPLETED`, or `FAILED`).
  final String status;

  /// Markdown produced by the Parser (Lesson Planner) stage.
  final String? markdownContent;

  /// Structured sections produced by the Teacher stage.
  final List<Map<String, Object?>>? sections;

  /// Storyboard beats produced by the Storyboard stage.
  final List<Map<String, Object?>>? storyboardBeats;

  /// Narrated beats produced by the Narration (TTS) stage.
  final List<Map<String, Object?>>? narratedBeats;

  /// Servable video URL, present once [status] is `COMPLETED`.
  final String? videoUrl;

  /// Safe failure description, present once [status] is `FAILED`.
  final String? errorMessage;
}
