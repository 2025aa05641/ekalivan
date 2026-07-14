/// Dio-backed API client boundary.
library;

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

  /// Base URL this client sends requests against, for building absolute
  /// URLs from server-returned relative paths (e.g. a rendered video's path).
  String get baseUrl => _dio.options.baseUrl;

  /// Sends a POST request and returns the decoded object response.
  Future<Map<String, Object?>> post(String path, {required Map<String, Object?> data}) async {
    return _send(() => _dio.post<Map<String, Object?>>(path, data: data));
  }

  /// Sends a GET request and returns the decoded object response.
  ///
  /// Explicitly disables caching: this is used for status polling, where a
  /// cached response would make the client stop observing real progress.
  Future<Map<String, Object?>> get(String path) async {
    return _send(
      () => _dio.get<Map<String, Object?>>(
        path,
        options: Options(headers: const <String, String>{'Cache-Control': 'no-cache'}),
      ),
    );
  }

  Future<Map<String, Object?>> _send(Future<Response<Map<String, Object?>>> Function() request) async {
    try {
      final Response<Map<String, Object?>> response = await request();
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
    if (exception.response?.statusCode == 404) {
      return const ApiException('This video could not be found.');
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
