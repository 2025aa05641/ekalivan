import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/recent_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/generation_screen.dart';

class _FakeVideoRepository implements IVideoRepository {
  @override
  Future<String> uploadVideoSource({required List<int> bytes, required String filename}) => throw UnimplementedError();
  _FakeVideoRepository(this._updates);

  final List<VideoStatusUpdateEntity> _updates;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) {
    throw UnimplementedError('Not exercised by this screen.');
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) {
    return Stream<VideoStatusUpdateEntity>.fromIterable(_updates);
  }

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Future<List<RecentJobEntity>> getRecentJobs({int limit = 20}) async => <RecentJobEntity>[];
}

Future<void> _pumpGenerationScreen(WidgetTester tester, List<VideoStatusUpdateEntity> updates) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        videoRepositoryProvider.overrideWithValue(_FakeVideoRepository(updates)),
      ],
      child: const MaterialApp(home: GenerationScreen(taskId: 'job-1')),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows plain-language progress while the job is processing', (WidgetTester tester) async {
    await _pumpGenerationScreen(tester, const <VideoStatusUpdateEntity>[
      VideoStatusUpdateEntity(progress: 55, currentNode: 'Creating your video…', status: 'PROCESSING'),
    ]);

    expect(find.text('Creating your video…'), findsOneWidget);
  });

  testWidgets('shows an accessible error when the job fails', (WidgetTester tester) async {
    await _pumpGenerationScreen(tester, const <VideoStatusUpdateEntity>[
      VideoStatusUpdateEntity(
        progress: 0,
        currentNode: 'Something went wrong',
        status: 'FAILED',
        errorMessage: 'The chapter file could not be read.',
      ),
    ]);

    expect(find.text('The chapter file could not be read.'), findsOneWidget);
  });

  testWidgets('shows the ready heading once the job completes', (WidgetTester tester) async {
    await _pumpGenerationScreen(tester, const <VideoStatusUpdateEntity>[
      VideoStatusUpdateEntity(
        progress: 100,
        currentNode: 'Your video is ready!',
        status: 'COMPLETED',
        videoUrl: '/static/video/job-1/final.mp4',
      ),
    ]);

    expect(find.text('Your video is ready!'), findsOneWidget);
  });
}
