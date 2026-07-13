/// Dio-backed API client boundary.
import 'package:dio/dio.dart';

/// Owns HTTP configuration and maps transport failures to stable exceptions.
class ApiClient {
  /// Creates a client configured with the backend base URL.
  ApiClient({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: baseUrl ?? const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000'),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
                headers: const <String, String>{'Content-Type': 'application/json'},
              ),
            ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException error, ErrorInterceptorHandler handler) {
          handler.reject(error.copyWith(error: ApiException.fromDio(error)));
        },
      ),
    );
  }

  final Dio _dio;

  /// Sends a POST request and returns the decoded object response.
  Future<Map<String, Object?>> post(String path, {required Map<String, Object?> data}) async {
    try {
      final Response<Map<String, Object?>> response = await _dio.post<Map<String, Object?>>(path, data: data);
      return response.data ?? <String, Object?>{};
    } on DioException catch (error) {
      final Object? cause = error.error;
      if (cause is ApiException) {
        throw cause;
      }
      throw ApiException.fromDio(error);
    }
  }
}

/// Stable presentation-safe representation of a transport failure.
class ApiException implements Exception {
  /// Creates an API exception with a human-readable message.
  const ApiException(this.message);

  /// Produces a stable failure from Dio's potentially vendor-specific details.
  factory ApiException.fromDio(DioException exception) {
    if (exception.type == DioExceptionType.connectionTimeout || exception.type == DioExceptionType.receiveTimeout) {
      return const ApiException('The connection took too long. Please try again.');
    }
    if (exception.response?.statusCode == 503) {
      return const ApiException('The service is temporarily unavailable. Please try again soon.');
    }
    return const ApiException('Unable to reach the learning service.');
  }

  /// Safe user-facing error message.
  final String message;

  @override
  String toString() => message;
}
