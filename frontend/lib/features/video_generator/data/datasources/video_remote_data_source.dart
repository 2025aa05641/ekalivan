/// Remote datasource for the documented FastAPI contract.
import '../../../../core/network/api_client.dart';
import '../../domain/value_objects/video_generation_request_params.dart';
import '../models/video_generation_response_model.dart';

/// Isolates raw HTTP request and response mapping from the repository.
class VideoRemoteDataSource {
  /// Creates a datasource with an injected API client.
  const VideoRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// Calls the accepted-job endpoint.
  Future<VideoGenerationResponseModel> requestGeneration(VideoGenerationRequestParams params) async {
    final Map<String, Object?> response = await _apiClient.post(
      '/api/v1/videos/generate',
      data: <String, Object?>{
        'class_level': params.classLevel,
        'subject': params.subject,
        'chapter_title': params.chapterTitle,
        'file_storage_path': params.fileStoragePath,
      },
    );
    return VideoGenerationResponseModel.fromJson(response);
  }
}
