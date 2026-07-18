/// Domain entity representing a lightweight recent-job summary for the dashboard.
library;

/// Immutable summary of a recent video-generation job.
class RecentJobEntity {
  /// Creates an immutable recent job entity.
  const RecentJobEntity({
    required this.taskId,
    required this.status,
    required this.subject,
    required this.chapterTitle,
    required this.classLevel,
    required this.createdAt,
  });

  /// Server-generated UUID task identifier (as a string).
  final String taskId;

  /// Current task lifecycle status: QUEUED, PROCESSING, COMPLETED, FAILED.
  final String status;

  /// Subject of the chapter (e.g. "Science").
  final String subject;

  /// Chapter title (e.g. "The World of Plants").
  final String chapterTitle;

  /// Class / grade level (e.g. "Class 6").
  final String classLevel;

  /// When the job was created on the server.
  final DateTime createdAt;
}
