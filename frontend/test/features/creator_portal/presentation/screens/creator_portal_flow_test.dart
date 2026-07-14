import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
import 'package:textbook_video_learning/core/widgets/primary_button.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/admin_dashboard_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/login_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/pipeline_complete_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/pipeline_progress_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/rendering_progress_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/upload_book_screen.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';

class _UnusedVideoRepository implements IVideoRepository {
  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) {
    throw UnimplementedError('Not exercised by the creator portal.');
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) => const Stream.empty();

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];
}

void main() {
  testWidgets('walks the full mock flow from login to pipeline completion', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[videoRepositoryProvider.overrideWithValue(_UnusedVideoRepository())],
        child: const TextbookVideoApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Creator Portal'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Admin Portal'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.byType(AdminDashboardScreen), findsOneWidget);
    expect(find.text('Total Books'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('+ Upload New Book'), 200);
    await tester.tap(find.text('+ Upload New Book'));
    await tester.pumpAndSettle();
    expect(find.byType(UploadBookScreen), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Upload & Process'), 200);
    await tester.tap(find.text('Upload & Process'));
    // PipelineProgressScreen's "current" step uses an indeterminate
    // CircularProgressIndicator, which animates forever and never lets
    // pumpAndSettle finish — pump a bounded number of frames instead.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PipelineProgressScreen), findsOneWidget);
    expect(find.text('Video Rendering'), findsOneWidget);

    await tester.tap(find.text('Video Rendering'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(RenderingProgressScreen), findsOneWidget);
    expect(find.text('Rendering Video'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Continue When Ready'),
      200,
      scrollable: find.descendant(of: find.byType(RenderingProgressScreen), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.text('Continue When Ready'));
    await tester.pumpAndSettle();
    expect(find.byType(PipelineCompleteScreen), findsOneWidget);
    expect(find.text('Video Generated Successfully'), findsOneWidget);
  });

  testWidgets('upload requires a selected file before processing can start', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[videoRepositoryProvider.overrideWithValue(_UnusedVideoRepository())],
        child: const MaterialApp(home: UploadBookScreen()),
      ),
    );

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    final PrimaryButton button = tester.widget(find.byType(PrimaryButton));
    expect(button.onPressed, isNull);
  });
}
