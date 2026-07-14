import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
import 'package:textbook_video_learning/core/widgets/video_card.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/chapter_detail_screen.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/chapter_list_screen.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/class_selection_screen.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/medium_selection_screen.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/student_splash_screen.dart';
import 'package:textbook_video_learning/features/student_portal/presentation/screens/subject_selection_screen.dart';

void main() {
  testWidgets('walks from the home screen through the full student flow to a chapter', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: TextbookVideoApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Student Portal'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentSplashScreen), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(MediumSelectionScreen), findsOneWidget);

    await tester.tap(find.text('English Medium'));
    await tester.pumpAndSettle();
    expect(find.byType(ClassSelectionScreen), findsOneWidget);

    await tester.tap(find.text('Grade 6'));
    await tester.pumpAndSettle();
    expect(find.byType(SubjectSelectionScreen), findsOneWidget);

    await tester.tap(find.text('Science'));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterListScreen), findsOneWidget);

    // Chapter 2 (unlike Chapter 1) is still a placeholder, so tapping it
    // here doesn't require faking a video-generation backend.
    await tester.tap(find.text('Watch Lesson').at(1));
    await tester.pumpAndSettle();
    expect(find.byType(ChapterDetailScreen), findsOneWidget);
    expect(find.text('Chapter 2'), findsOneWidget);
    expect(find.text('Food and Nutrition'), findsWidgets);

    await tester.tap(find.byType(VideoCard));
    await tester.pump();
    expect(find.text('This lesson is being prepared.'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Photosynthesis'), 200);
    expect(find.text('Photosynthesis'), findsOneWidget);
  });

  testWidgets('a subject without chapters shows a coming-soon message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: ChapterListScreen(medium: 'english', grade: '6', subject: 'mathematics')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chapters for this subject are coming soon.'), findsOneWidget);
  });
}
