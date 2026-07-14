/// Data transfer model for the generation acceptance API response.
library;

import '../../domain/entities/video_job_entity.dart';

/// Maps the backend's accepted-job JSON into the domain entity.
class VideoGenerationResponseModel {
  /// Creates a response model from its API fields.
  const VideoGenerationResponseModel({required this.taskId, required this.status, this.estimatedTimeSeconds});

  /// Parses a checked JSON object from the API client.
  ///
  /// The backend does not currently send `estimated_time_seconds`; it is
  /// read defensively so the client stays correct if that changes.
  factory VideoGenerationResponseModel.fromJson(Map<String, Object?> json) {
    return VideoGenerationResponseModel(
      taskId: json['task_id']! as String,
      status: json['status']! as String,
      estimatedTimeSeconds: (json['estimated_time_seconds'] as num?)?.toDouble(),
    );
  }

  /// API task identifier.
  final String taskId;

  /// API lifecycle status.
  final String status;

  /// Optional server estimate.
  final double? estimatedTimeSeconds;

  /// Converts this DTO into a technology-independent domain entity.
  VideoJobEntity toEntity() => VideoJobEntity(
        taskId: taskId,
        status: status,
        estimatedTimeSeconds: estimatedTimeSeconds,
      );
}
