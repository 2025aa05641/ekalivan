import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/app.dart';
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

    await tester.tap(find.text('Watch Lesson').first);
    await tester.pumpAndSettle();
    expect(find.byType(ChapterDetailScreen), findsOneWidget);
    expect(find.text('Chapter 1'), findsOneWidget);
    expect(find.text('The World of Plants'), findsWidgets);

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
