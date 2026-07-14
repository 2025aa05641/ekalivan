/// Stand-in chapter used until a real chapter-catalog/upload backend exists.
library;

import '../../features/video_generator/domain/value_objects/video_generation_request_params.dart';

/// The one chapter file present in every checkout (it backs the backend's
/// own test suite). The backend has no endpoint to list chapters or accept
/// an uploaded PDF, only to generate from a known server-side file path —
/// used here by both the Student and Creator portals until that exists.
const VideoGenerationRequestParams demoChapter = VideoGenerationRequestParams(
  classLevel: '6',
  subject: 'Science',
  chapterTitle: 'The World of Plants',
  fileStoragePath: 'tests/fixtures/sample_chapter.txt',
);
