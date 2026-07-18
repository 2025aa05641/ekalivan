import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
import 'package:textbook_video_learning/core/widgets/primary_button.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/admin_dashboard_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/login_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/pipeline_progress_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/upload_book_screen.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/recent_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';

class _FakeCreatorRepository implements IVideoRepository {
  _FakeCreatorRepository({this.jobToReturn, this.errorToThrow, this.updates = const <VideoStatusUpdateEntity>[]});

  final VideoJobEntity? jobToReturn;
  final Object? errorToThrow;
  final List<VideoStatusUpdateEntity> updates;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) async {
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
    return jobToReturn!;
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) =>
      Stream<VideoStatusUpdateEntity>.fromIterable(updates);

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];

  @override
  Future<List<RecentJobEntity>> getRecentJobs({int limit = 20}) async => <RecentJobEntity>[];
}

void main() {
  testWidgets('walks from login through upload to a real accepted job', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWithValue(
            _FakeCreatorRepository(
              jobToReturn: const VideoJobEntity(taskId: 'job-42', status: 'QUEUED'),
              updates: const <VideoStatusUpdateEntity>[
                VideoStatusUpdateEntity(progress: 10, currentNode: 'Waiting in line…', status: 'QUEUED'),
              ],
            ),
          ),
        ],
        child: const TextbookVideoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Creator Portal'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('+ Upload New Book'), 200);
    await tester.tap(find.text('+ Upload New Book'));
    await tester.pumpAndSettle();
    expect(find.byType(UploadBookScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Upload & Process'), 200);
    await tester.tap(find.text('Upload & Process'));
    // The pipeline screen's "current" step uses an indeterminate spinner,
    // which animates forever and never lets pumpAndSettle finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final PipelineProgressScreen screen = tester.widget<PipelineProgressScreen>(find.byType(PipelineProgressScreen));
    expect(screen.taskId, 'job-42');
  });

  testWidgets('a failed request stays on the upload screen and surfaces the error', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          videoRepositoryProvider.overrideWithValue(
            _FakeCreatorRepository(errorToThrow: Exception('Unable to reach the learning service.')),
          ),
        ],
        child: const MaterialApp(home: UploadBookScreen()),
      ),
    );

    await tester.scrollUntilVisible(find.text('Upload & Process'), 200);
    await tester.tap(find.text('Upload & Process'));
    await tester.pumpAndSettle();

    expect(find.byType(PipelineProgressScreen), findsNothing);
    expect(find.textContaining('Unable to reach the learning service.'), findsOneWidget);
  });

  testWidgets('upload requires a selected file before processing can start', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: UploadBookScreen())),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });
}
