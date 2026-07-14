import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textbook_video_learning/core/widgets/accessible_error_widget.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/pipeline_complete_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/pipeline_progress_screen.dart';
import 'package:textbook_video_learning/features/creator_portal/presentation/screens/rendering_progress_screen.dart';
import 'package:textbook_video_learning/features/video_generator/data/datasources/local_video_cache.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_status_update_entity.dart';
import 'package:textbook_video_learning/features/video_generator/domain/repositories/video_repository.dart';
import 'package:textbook_video_learning/features/video_generator/domain/value_objects/video_generation_request_params.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/providers/video_generation_provider.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/widgets/video_player_view.dart';

class _FakeRepository implements IVideoRepository {
  _FakeRepository(this._updates);

  final List<VideoStatusUpdateEntity> _updates;

  @override
  Future<VideoJobEntity> requestVideoGeneration({required VideoGenerationRequestParams params}) {
    throw UnimplementedError('Not exercised by these screens.');
  }

  @override
  Stream<VideoStatusUpdateEntity> watchGenerationProgress({required String taskId}) =>
      Stream<VideoStatusUpdateEntity>.fromIterable(_updates);

  @override
  Future<List<VideoJobEntity>> getOfflineCachedVideos() async => <VideoJobEntity>[];
}

Future<void> _pump(WidgetTester tester, Widget screen, List<VideoStatusUpdateEntity> updates) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[videoRepositoryProvider.overrideWithValue(_FakeRepository(updates))],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('PipelineProgressScreen', () {
    testWidgets('marks earlier steps completed and the current one in progress at 55%', (WidgetTester tester) async {
      await _pump(tester, const PipelineProgressScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(progress: 55, currentNode: 'Creating your video…', status: 'PROCESSING'),
      ]);

      for (final String completed in pipelineStageNames.take(4)) {
        expect(find.text(completed), findsOneWidget);
      }
      expect(find.text('Video Rendering'), findsOneWidget);
    });

    testWidgets('shows every step completed once the job is done', (WidgetTester tester) async {
      await _pump(tester, const PipelineProgressScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(
          progress: 100,
          currentNode: 'Your video is ready!',
          status: 'COMPLETED',
          videoUrl: '/static/video/job-1/final.mp4',
        ),
      ]);

      expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(pipelineStageNames.length));
    });

    testWidgets('shows an accessible error when the job fails', (WidgetTester tester) async {
      await _pump(tester, const PipelineProgressScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(
          progress: 0,
          currentNode: 'Something went wrong',
          status: 'FAILED',
          errorMessage: 'The chapter file could not be read.',
        ),
      ]);

      expect(find.text('The chapter file could not be read.'), findsOneWidget);
    });
  });

  group('RenderingProgressScreen', () {
    testWidgets('shows the real progress percentage and current stage', (WidgetTester tester) async {
      await _pump(tester, const RenderingProgressScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(progress: 55, currentNode: 'Creating your video…', status: 'PROCESSING'),
      ]);

      expect(find.text('55%'), findsOneWidget);
      expect(find.text('Creating your video…'), findsOneWidget);

      final LinearProgressIndicator bar = tester.widget(find.byType(LinearProgressIndicator));
      expect(bar.value, closeTo(0.55, 0.001));
    });

    testWidgets('shows an accessible error when the job fails', (WidgetTester tester) async {
      await _pump(tester, const RenderingProgressScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(
          progress: 0,
          currentNode: 'Something went wrong',
          status: 'FAILED',
          errorMessage: 'FFmpeg exited with a non-zero status.',
        ),
      ]);

      expect(find.text('FFmpeg exited with a non-zero status.'), findsOneWidget);
    });
  });

  group('PipelineCompleteScreen', () {
    testWidgets('shows a not-finished message while the job is still processing', (WidgetTester tester) async {
      await _pump(tester, const PipelineCompleteScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(progress: 55, currentNode: 'Creating your video…', status: 'PROCESSING'),
      ]);

      expect(find.byType(AccessibleErrorWidget), findsOneWidget);
      expect(find.byType(VideoPlayerView), findsNothing);
    });

    testWidgets('shows the video player and a working publish action once completed', (WidgetTester tester) async {
      await _pump(tester, const PipelineCompleteScreen(taskId: 'job-1'), const <VideoStatusUpdateEntity>[
        VideoStatusUpdateEntity(
          progress: 100,
          currentNode: 'Your video is ready!',
          status: 'COMPLETED',
          videoUrl: '/static/video/job-1/final.mp4',
        ),
      ]);

      expect(find.text('Video Generated Successfully'), findsOneWidget);
      expect(find.byType(VideoPlayerView), findsOneWidget);

      await tester.scrollUntilVisible(find.text('Publish for Students'), 200);
      await tester.tap(find.text('Publish for Students'));
      await tester.pump();

      expect(find.text('Published'), findsOneWidget);
      final List<VideoJobEntity> cached = await const LocalVideoCache().getAll();
      expect(cached.single.taskId, 'job-1');
      expect(cached.single.videoUrl, '/static/video/job-1/final.mp4');
    });
  });
}
