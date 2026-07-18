/// Data transfer model for the recent-jobs list API response.
library;

import '../../domain/entities/recent_job_entity.dart';

/// Maps one element of the `GET /api/v1/videos/` JSON array into a domain entity.
class RecentJobModel {
  /// Creates a model from its parsed JSON fields.
  const RecentJobModel({
    required this.taskId,
    required this.status,
    required this.subject,
    required this.chapterTitle,
    required this.classLevel,
    required this.createdAt,
  });

  /// Parses a checked JSON object from the API client.
  factory RecentJobModel.fromJson(Map<String, Object?> json) {
    return RecentJobModel(
      taskId: json['task_id']! as String,
      status: (json['status']! as String),
      subject: json['subject']! as String,
      chapterTitle: json['chapter_title']! as String,
      classLevel: json['class_level']! as String,
      createdAt: DateTime.parse(json['created_at']! as String),
    );
  }

  /// API task identifier (UUID string).
  final String taskId;

  /// Lifecycle status string.
  final String status;

  /// Subject name.
  final String subject;

  /// Chapter title.
  final String chapterTitle;

  /// Class / grade level.
  final String classLevel;

  /// ISO 8601 creation timestamp.
  final DateTime createdAt;

  /// Converts this DTO to a technology-independent domain entity.
  RecentJobEntity toEntity() => RecentJobEntity(
        taskId: taskId,
        status: status,
        subject: subject,
        chapterTitle: chapterTitle,
        classLevel: classLevel,
        createdAt: createdAt,
      );
}
