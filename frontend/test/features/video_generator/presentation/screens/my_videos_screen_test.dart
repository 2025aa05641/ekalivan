import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/cached_video_screen.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/my_videos_screen.dart';

class _FakeVideoRepository implements IVideoRepository {
  _FakeVideoRepository({this.cachedVideos = const <VideoJobEntity>[]});

  final List<VideoJobEntity> cachedVideos;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) {
    throw UnimplementedError('Not exercised by this screen.');
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) => const Stream.empty();

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => cachedVideos;
}

Future<void> _pumpAtMyVideos(WidgetTester tester, List<VideoJobEntity> cachedVideos) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        videoRepositoryProvider.overrideWithValue(_FakeVideoRepository(cachedVideos: cachedVideos)),
      ],
      child: const TextbookVideoApp(),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.video_library));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows a friendly empty state when nothing is cached', (WidgetTester tester) async {
    await _pumpAtMyVideos(tester, const <VideoJobEntity>[]);

    expect(find.byType(MyVideosScreen), findsOneWidget);
    expect(find.textContaining("haven't watched any videos yet"), findsOneWidget);
  });

  testWidgets('lists each cached video', (WidgetTester tester) async {
    await _pumpAtMyVideos(tester, const <VideoJobEntity>[
      VideoJobEntity(taskId: 'aaaaaaaa-1111', status: 'COMPLETED', videoUrl: '/static/video/aaaaaaaa/final.mp4'),
      VideoJobEntity(taskId: 'bbbbbbbb-2222', status: 'COMPLETED', videoUrl: '/static/video/bbbbbbbb/final.mp4'),
    ]);

    expect(find.textContaining('aaaaaaaa'), findsOneWidget);
    expect(find.textContaining('bbbbbbbb'), findsOneWidget);
  });

  testWidgets('tapping a cached video navigates to its player with the right entity', (WidgetTester tester) async {
    const VideoJobEntity cached = VideoJobEntity(
      taskId: 'cccccccc-3333',
      status: 'COMPLETED',
      videoUrl: '/static/video/cccccccc/final.mp4',
    );
    await _pumpAtMyVideos(tester, const <VideoJobEntity>[cached]);

    await tester.tap(find.textContaining('cccccccc'));
    await tester.pumpAndSettle();

    final CachedVideoScreen screen = tester.widget<CachedVideoScreen>(find.byType(CachedVideoScreen));
    expect(screen.job.taskId, 'cccccccc-3333');
    expect(screen.job.videoUrl, '/static/video/cccccccc/final.mp4');
  });
}
