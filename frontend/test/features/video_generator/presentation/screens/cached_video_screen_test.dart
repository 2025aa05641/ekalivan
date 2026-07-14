import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/features/video_generator/domain/entities/video_job_entity.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/screens/cached_video_screen.dart';

void main() {
  testWidgets('shows the player heading when the cached job has a video URL', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CachedVideoScreen(
            job: VideoJobEntity(taskId: 'job-1', status: 'COMPLETED', videoUrl: '/static/video/job-1/final.mp4'),
          ),
        ),
      ),
    );

    expect(find.text('Watch again'), findsOneWidget);
  });

  testWidgets('shows an accessible error when the cached job has no video URL', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: CachedVideoScreen(job: VideoJobEntity(taskId: 'job-2', status: 'COMPLETED')),
        ),
      ),
    );

    expect(find.text('This saved video is no longer available.'), findsOneWidget);
    expect(find.text('Watch again'), findsNothing);
  });
}
