import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:textbook_video_learning/core/widgets/video_card.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/chapter_detail_screen.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/recent_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/router_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/cached_video_screen.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/generation_screen.dart';

class _FakeRepository implements IVideoRepository {
  @override
  Future<String> uploadVideoSource({required List<int> bytes, required String filename}) => throw UnimplementedError();
  _FakeRepository({this.cached = const <VideoJobEntity>[], this.jobToReturn});

  final List<VideoJobEntity> cached;
  final VideoJobEntity? jobToReturn;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async =>
      jobToReturn!;

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) =>
      const Stream<VideoStatusUpdateEntity>.empty();

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => cached;

  @override
  Future<List<RecentJobEntity>> getRecentJobs({int limit = 20}) async => <RecentJobEntity>[];
}

/// Minimal router covering just what ChapterDetailScreen navigates to,
/// so `context.pushNamed` resolves without pulling in the full app router.
GoRouter _testRouter() => GoRouter(
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          name: 'chapterDetail',
          builder: (BuildContext context, GoRouterState state) =>
              const ChapterDetailScreen(medium: 'english', grade: '6', subject: 'science', chapterId: '1'),
        ),
        GoRoute(
          path: '/videos/:taskId',
          name: AppRoute.generation.routeName,
          builder: (BuildContext context, GoRouterState state) =>
              GenerationScreen(taskId: state.pathParameters['taskId']!),
        ),
        GoRoute(
          path: '/cached',
          name: AppRoute.cachedVideo.routeName,
          builder: (BuildContext context, GoRouterState state) =>
              CachedVideoScreen(job: state.extra! as VideoJobEntity),
        ),
      ],
    );

Future<void> _pump(WidgetTester tester, IVideoRepository repository) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[videoRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(routerConfig: _testRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('plays the cached video directly when one is already published', (WidgetTester tester) async {
    await _pump(
      tester,
      _FakeRepository(
        cached: const <VideoJobEntity>[
          VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/static/video/job-1/final.mp4'),
        ],
      ),
    );

    await tester.tap(find.byType(VideoCard));
    await tester.pumpAndSettle();

    expect(find.byType(CachedVideoScreen), findsOneWidget);
  });

  testWidgets('starts a real generation job when nothing is cached yet', (WidgetTester tester) async {
    await _pump(tester, _FakeRepository(jobToReturn: const VideoJobEntity(taskId: 'job-42', status: 'QUEUED')));

    await tester.tap(find.byType(VideoCard));
    // GenerationScreen watches an indeterminate spinner while queued.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final GenerationScreen screen = tester.widget<GenerationScreen>(find.byType(GenerationScreen));
    expect(screen.taskId, 'job-42');
  });

  testWidgets('a placeholder chapter still shows the coming-soon message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ChapterDetailScreen(medium: 'english', grade: '6', subject: 'science', chapterId: '2'),
        ),
      ),
    );

    await tester.tap(find.byType(VideoCard));
    await tester.pump();

    expect(find.text('This lesson is being prepared.'), findsOneWidget);
  });
}
