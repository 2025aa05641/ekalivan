/// Data transfer model for the job-status polling API response.
library;

import '../../domain/entities/video_status_update_entity.dart';

/// Maps the backend's job-status JSON into a domain progress update.
///
/// Parses all per-stage payload fields so the pipeline screen can display
/// exactly what the AI produced at each step.
class JobStatusResponseModel {
  /// Creates a response model from its API fields.
  const JobStatusResponseModel({
    required this.taskId,
    required this.status,
    this.progressNode,
    this.markdownContent,
    this.sections,
    this.storyboardBeats,
    this.narratedBeats,
    this.videoUrl,
    this.errorMessage,
  });

  /// Parses a checked JSON object from the API client.
  factory JobStatusResponseModel.fromJson(Map<String, Object?> json) {
    return JobStatusResponseModel(
      taskId: json['task_id']! as String,
      status: json['status']! as String,
      progressNode: json['progress_node'] as String?,
      markdownContent: json['markdown_content'] as String?,
      sections: _parseListOfMaps(json['sections']),
      storyboardBeats: _parseListOfMaps(json['storyboard_beats']),
      narratedBeats: _parseListOfMaps(json['narrated_beats']),
      videoUrl: json['video_url'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  static List<Map<String, Object?>>? _parseListOfMaps(Object? value) {
    if (value == null) return null;
    if (value is List) {
      return value.whereType<Map<String, Object?>>().toList();
    }
    return null;
  }

  /// API task identifier.
  final String taskId;

  /// API lifecycle status.
  final String status;

  /// Currently-running pipeline node name (e.g. "Lesson Planner", "Video Rendering").
  final String? progressNode;

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

  /// Converts this DTO into a technology-independent domain entity.
  VideoStatusUpdateEntity toEntity() => VideoStatusUpdateEntity(
        progress: _progressFor(),
        currentNode: progressNode ?? _labelFor(status),
        status: status,
        markdownContent: markdownContent,
        sections: sections,
        storyboardBeats: storyboardBeats,
        narratedBeats: narratedBeats,
        videoUrl: videoUrl,
        errorMessage: errorMessage,
      );

  double _progressFor() {
    // Use actual field presence to compute real progress.
    if (status == 'COMPLETED') return 100;
    if (status == 'FAILED') return 0;
    // Mirror the named nodes sent by the backend LangGraph pipeline. These
    // values are authoritative while a job is processing.
    final double? nodeProgress = switch (progressNode) {
      'Textbook Parsing' => 5,
      'Curriculum Mapping' => 18,
      'Lesson Planning' => 31,
      'Teacher Script' => 44,
      'Storyboard' => 57,
      'Narration (TTS)' => 70,
      'Video Rendering' => 83,
      'Publishing' => 94,
      _ => null,
    };
    if (nodeProgress != null) return nodeProgress;
    if (videoUrl != null) return 100;
    if (narratedBeats != null && narratedBeats!.isNotEmpty) return 62; // step 5 – video rendering
    if (storyboardBeats != null && storyboardBeats!.isNotEmpty) return 50; // step 4 – narration
    if (sections != null && sections!.isNotEmpty) return 37; // step 3 – storyboard
    if (markdownContent != null) return 25; // step 2 – teacher
    if (status == 'PROCESSING') return 12; // step 1 – lesson planner
    return 10; // QUEUED
  }

  static String _labelFor(String status) => switch (status) {
        'QUEUED' => 'Waiting in line…',
        'PROCESSING' => 'Creating your video…',
        'COMPLETED' => 'Your video is ready!',
        _ => 'Something went wrong',
      };
}
