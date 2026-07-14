import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/core/network/api_client.dart';
import 'package:textbook_video_learning/features/video_generator/data/datasources/video_remote_data_source.dart';
import 'package:textbook_video_learning/features/video_generator/data/repositories/video_repository_impl.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';

/// Deterministic fake transport returning a scripted sequence of job-status
/// bodies, one per GET request, so the repository's real polling loop can be
/// exercised without a live backend.
class _ScriptedHttpClientAdapter implements HttpClientAdapter {
  _ScriptedHttpClientAdapter(this._responses, {Set<int> failAtIndices = const <int>{}})
      : _failAtIndices = failAtIndices;

  final List<String> _responses;
  final Set<int> _failAtIndices;
  int _callCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final int index = _callCount;
    _callCount++;
    if (_failAtIndices.contains(index)) {
      throw DioException.connectionError(requestOptions: options, reason: 'Simulated transient network failure.');
    }
    final String body = _responses[index.clamp(0, _responses.length - 1)];
    return ResponseBody.fromString(
      body,
      200,
      headers: <String, List<String>>{
        Headers.contentTypeHeader: <String>[Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

VideoRepositoryImpl _repositoryWithScriptedResponses(
  List<String> responses, {
  Set<int> failAtIndices = const <int>{},
  int maxConsecutivePollFailures = 3,
}) {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://test'))
    ..httpClientAdapter = _ScriptedHttpClientAdapter(responses, failAtIndices: failAtIndices);
  final ApiClient apiClient = ApiClient(dio: dio);
  return VideoRepositoryImpl(
    VideoRemoteDataSource(apiClient),
    pollInterval: const Duration(milliseconds: 1),
    maxConsecutivePollFailures: maxConsecutivePollFailures,
  );
}

void main() {
  test('watchGenerationProgress polls until COMPLETED and then stops', () async {
    final VideoRepositoryImpl repository = _repositoryWithScriptedResponses(<String>[
      '{"task_id":"job-1","status":"QUEUED"}',
      '{"task_id":"job-1","status":"PROCESSING"}',
      '{"task_id":"job-1","status":"COMPLETED","video_url":"/static/video/job-1/final.mp4"}',
    ]);

    final List<VideoStatusUpdateEntity> updates = await repository.watchGenerationProgress(taskId: 'job-1').toList();

    expect(updates.map((VideoStatusUpdateEntity update) => update.status), <String>[
      'QUEUED',
      'PROCESSING',
      'COMPLETED',
    ]);
    expect(updates.last.videoUrl, '/static/video/job-1/final.mp4');
    expect(updates.last.progress, 100);
  });

  test('watchGenerationProgress stops after FAILED and carries the error message', () async {
    final VideoRepositoryImpl repository = _repositoryWithScriptedResponses(<String>[
      '{"task_id":"job-2","status":"PROCESSING"}',
      '{"task_id":"job-2","status":"FAILED","error_message":"Simulated failure."}',
    ]);

    final List<VideoStatusUpdateEntity> updates = await repository.watchGenerationProgress(taskId: 'job-2').toList();

    expect(updates.last.status, 'FAILED');
    expect(updates.last.errorMessage, 'Simulated failure.');
  });

  test('a single transient poll failure does not end the stream', () async {
    final VideoRepositoryImpl repository = _repositoryWithScriptedResponses(
      <String>[
        '{"task_id":"job-3","status":"PROCESSING"}',
        '{"task_id":"job-3","status":"PROCESSING"}',
        '{"task_id":"job-3","status":"COMPLETED","video_url":"/static/video/job-3/final.mp4"}',
      ],
      failAtIndices: <int>{1},
    );

    final List<VideoStatusUpdateEntity> updates = await repository.watchGenerationProgress(taskId: 'job-3').toList();

    expect(updates.map((VideoStatusUpdateEntity update) => update.status), <String>['PROCESSING', 'COMPLETED']);
  });

  test('the stream ends in an error once consecutive poll failures exceed the limit', () async {
    final VideoRepositoryImpl repository = _repositoryWithScriptedResponses(
      <String>['{"task_id":"job-4","status":"PROCESSING"}'],
      failAtIndices: <int>{0, 1, 2},
      maxConsecutivePollFailures: 3,
    );

    await expectLater(repository.watchGenerationProgress(taskId: 'job-4'), emitsError(isA<StateError>()));
  });
}
