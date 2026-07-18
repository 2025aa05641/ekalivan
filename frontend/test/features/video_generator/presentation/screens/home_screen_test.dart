import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/recent_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/generation_screen.dart';

class _FakeVideoRepository implements IVideoRepository {
  _FakeVideoRepository({this.jobToReturn, this.errorToThrow});

  final VideoJobEntity? jobToReturn;
  final Object? errorToThrow;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return jobToReturn!;
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) => const Stream.empty();

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Future<List<RecentJobEntity>> getRecentJobs({int limit = 20}) async => <RecentJobEntity>[];
}

void main() {
  testWidgets('tapping Science requests generation and navigates to the generation screen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWithValue(
            _FakeVideoRepository(jobToReturn: const VideoJobEntity(taskId: 'job-42', status: 'QUEUED')),
          ),
        ],
        child: const TextbookVideoApp(),
      ),
    );

    await tester.tap(find.text('Science'));
    await tester.pumpAndSettle();

    final GenerationScreen screen = tester.widget<GenerationScreen>(find.byType(GenerationScreen));
    expect(screen.taskId, 'job-42');
  });

  testWidgets('a failed request stays on the home screen and surfaces the error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWithValue(
            _FakeVideoRepository(errorToThrow: Exception('Unable to reach the learning service.')),
          ),
        ],
        child: const TextbookVideoApp(),
      ),
    );

    await tester.tap(find.text('Science'));
    await tester.pumpAndSettle();

    expect(find.byType(GenerationScreen), findsNothing);
    expect(find.textContaining('Unable to reach the learning service.'), findsOneWidget);
  });

  testWidgets('Mathematics is disabled and never triggers a request', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWithValue(
            _FakeVideoRepository(jobToReturn: const VideoJobEntity(taskId: 'unused', status: 'QUEUED')),
          ),
        ],
        child: const TextbookVideoApp(),
      ),
    );

    expect(find.text('Coming soon'), findsOneWidget);
    await tester.tap(find.text('Mathematics'));
    await tester.pumpAndSettle();

    expect(find.byType(GenerationScreen), findsNothing);
  });
}
