/// Parameters required to request generation from the domain layer.
class VideoGenerationRequestParams {
  /// Creates validated-by-caller generation request parameters.
  const VideoGenerationRequestParams({
    required this.classLevel,
    required this.subject,
    required this.chapterTitle,
    required this.fileStoragePath,
  });

  /// Student class level.
  final String classLevel;

  /// Textbook subject.
  final String subject;

  /// Requested chapter title.
  final String chapterTitle;

  /// Backend-visible uploaded textbook file location.
  final String fileStoragePath;
}
