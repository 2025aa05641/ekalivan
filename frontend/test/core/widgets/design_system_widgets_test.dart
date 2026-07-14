import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/core/theme/app_theme.dart';
import 'package:textbook_video_learning/core/widgets/app_scaffold.dart';
import 'package:textbook_video_learning/core/widgets/bottom_nav.dart';
import 'package:textbook_video_learning/core/widgets/chapter_card.dart';
import 'package:textbook_video_learning/core/widgets/dashboard_card.dart';
import 'package:textbook_video_learning/core/widgets/gradient_header.dart';
import 'package:textbook_video_learning/core/widgets/metric_card.dart';
import 'package:textbook_video_learning/core/widgets/pipeline_step.dart';
import 'package:textbook_video_learning/core/widgets/primary_button.dart';
import 'package:textbook_video_learning/core/widgets/rounded_input.dart';
import 'package:textbook_video_learning/core/widgets/secondary_button.dart';
import 'package:textbook_video_learning/core/widgets/status_chip.dart';
import 'package:textbook_video_learning/core/widgets/video_card.dart';

Widget _themed(Widget child) => MaterialApp(theme: AppTheme.lightTheme, home: Scaffold(body: child));

void main() {
  group('PrimaryButton', () {
    testWidgets('renders its label and invokes onPressed when tapped', (WidgetTester tester) async {
      var tapped = false;
      await tester.pumpWidget(_themed(PrimaryButton(label: 'Continue', onPressed: () => tapped = true)));

      expect(find.text('Continue'), findsOneWidget);
      await tester.tap(find.text('Continue'));
      expect(tapped, isTrue);
    });

    testWidgets('shows a progress indicator instead of the label while loading', (WidgetTester tester) async {
      await tester.pumpWidget(_themed(const PrimaryButton(label: 'Continue', onPressed: null, loading: true)));

      expect(find.text('Continue'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders as non-interactive when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(_themed(const PrimaryButton(label: 'Continue', onPressed: null)));

      final InkWell inkWell = tester.widget(find.byType(InkWell));
      expect(inkWell.onTap, isNull);
    });
  });

  testWidgets('SecondaryButton renders its label and invokes onPressed', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(_themed(SecondaryButton(label: 'Cancel', onPressed: () => tapped = true)));

    await tester.tap(find.text('Cancel'));
    expect(tapped, isTrue);
  });

  group('StatusChip', () {
    for (final (StatusChipKind kind, String label) in <(StatusChipKind, String)>[
      (StatusChipKind.success, 'Completed'),
      (StatusChipKind.inProgress, 'Processing'),
      (StatusChipKind.neutral, 'Queued'),
      (StatusChipKind.danger, 'Failed'),
    ]) {
      testWidgets('renders the $label label for ${kind.name}', (WidgetTester tester) async {
        await tester.pumpWidget(_themed(StatusChip(label: label, kind: kind)));

        expect(find.text(label), findsOneWidget);
      });
    }
  });

  group('PipelineStep', () {
    testWidgets('shows a check icon when completed', (WidgetTester tester) async {
      await tester.pumpWidget(
        _themed(const PipelineStep(stepNumber: 1, label: 'Lesson Planner', status: PipelineStepStatus.completed)),
      );

      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('Lesson Planner'), findsOneWidget);
    });

    testWidgets('shows a progress indicator when current', (WidgetTester tester) async {
      await tester.pumpWidget(
        _themed(const PipelineStep(stepNumber: 4, label: 'Narration', status: PipelineStepStatus.current)),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows an unchecked icon when pending', (WidgetTester tester) async {
      await tester.pumpWidget(
        _themed(const PipelineStep(stepNumber: 8, label: 'Final Publish', status: PipelineStepStatus.pending)),
      );

      expect(find.byIcon(Icons.radio_button_unchecked_rounded), findsOneWidget);
    });
  });

  testWidgets('BottomNav renders every item and reports the tapped index', (WidgetTester tester) async {
    int? tappedIndex;
    await tester.pumpWidget(
      _themed(
        BottomNav(
          items: const <BottomNavItem>[
            BottomNavItem(icon: Icons.home_rounded, label: 'Home'),
            BottomNavItem(icon: Icons.video_library_rounded, label: 'My Videos'),
          ],
          currentIndex: 0,
          onTap: (int index) => tappedIndex = index,
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('My Videos'), findsOneWidget);
    await tester.tap(find.text('My Videos'));
    expect(tappedIndex, 1);
  });

  testWidgets('MetricCard renders its value and label', (WidgetTester tester) async {
    await tester.pumpWidget(
      _themed(const MetricCard(icon: Icons.menu_book_rounded, value: '24', label: 'Total Books')),
    );

    expect(find.text('24'), findsOneWidget);
    expect(find.text('Total Books'), findsOneWidget);
  });

  testWidgets('ChapterCard renders its title, subtitle, and watch action', (WidgetTester tester) async {
    var watched = false;
    await tester.pumpWidget(
      _themed(
        ChapterCard(
          title: 'Chapter 1',
          subtitle: 'The World of Plants',
          icon: Icons.eco_rounded,
          onWatch: () => watched = true,
        ),
      ),
    );

    expect(find.text('Chapter 1'), findsOneWidget);
    await tester.tap(find.text('Watch Lesson'));
    expect(watched, isTrue);
  });

  testWidgets('VideoCard renders its title, duration, and invokes onTap', (WidgetTester tester) async {
    var tapped = false;
    await tester.pumpWidget(_themed(VideoCard(title: 'Photosynthesis', duration: '08:42', onTap: () => tapped = true)));

    expect(find.text('Photosynthesis'), findsOneWidget);
    expect(find.text('08:42'), findsOneWidget);
    await tester.tap(find.byType(VideoCard));
    expect(tapped, isTrue);
  });

  testWidgets('DashboardCard renders its child', (WidgetTester tester) async {
    await tester.pumpWidget(_themed(const DashboardCard(child: Text('Recent Activity'))));

    expect(find.text('Recent Activity'), findsOneWidget);
  });

  testWidgets('GradientHeader renders its child over the gradient', (WidgetTester tester) async {
    await tester.pumpWidget(_themed(const GradientHeader(child: Text('EKALIVAN'))));

    expect(find.text('EKALIVAN'), findsOneWidget);
  });

  testWidgets('RoundedInput renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(_themed(const RoundedInput(label: 'Email')));

    expect(find.text('Email'), findsOneWidget);
  });

  testWidgets('AppScaffold renders its body', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const AppScaffold(body: Text('Dashboard'))),
    );

    expect(find.text('Dashboard'), findsOneWidget);
  });
}
