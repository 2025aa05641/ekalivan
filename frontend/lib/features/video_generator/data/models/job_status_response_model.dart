/// Data transfer model for the job-status polling API response.
library;

import '../../domain/entities/video_status_update_entity.dart';

/// Maps the backend's job-status JSON into a domain progress update.
///
/// The backend currently exposes status through polling
/// (`GET /api/v1/videos/{task_id}`), not the architecture document's SSE
/// stream, so only the coarse lifecycle status is available here rather
/// than per-pipeline-node progress.
class JobStatusResponseModel {
  /// Creates a response model from its API fields.
  const JobStatusResponseModel({required this.taskId, required this.status, this.videoUrl, this.errorMessage});

  /// Parses a checked JSON object from the API client.
  factory JobStatusResponseModel.fromJson(Map<String, Object?> json) {
    return JobStatusResponseModel(
      taskId: json['task_id']! as String,
      status: json['status']! as String,
      videoUrl: json['video_url'] as String?,
      errorMessage: json['error_message'] as String?,
    );
  }

  /// API task identifier.
  final String taskId;

  /// API lifecycle status.
  final String status;

  /// Servable video URL, present once [status] is `COMPLETED`.
  final String? videoUrl;

  /// Safe failure description, present once [status] is `FAILED`.
  final String? errorMessage;

  /// Converts this DTO into a technology-independent domain entity.
  VideoStatusUpdateEntity toEntity() => VideoStatusUpdateEntity(
        progress: _progressFor(status),
        currentNode: _labelFor(status),
        status: status,
        videoUrl: videoUrl,
        errorMessage: errorMessage,
      );

  static double _progressFor(String status) => switch (status) {
        'QUEUED' => 10,
        'PROCESSING' => 55,
        'COMPLETED' => 100,
        _ => 0,
      };

  static String _labelFor(String status) => switch (status) {
        'QUEUED' => 'Waiting in line…',
        'PROCESSING' => 'Creating your video…',
        'COMPLETED' => 'Your video is ready!',
        _ => 'Something went wrong',
      };
}
