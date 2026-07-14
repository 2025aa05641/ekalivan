import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/widgets/adaptive_subject_card.dart';

void main() {
  testWidgets('debounces a burst of taps into a single onTap call while pending', (WidgetTester tester) async {
    int callCount = 0;
    final Completer<void> gate = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveSubjectCard(
          title: 'Science',
          color: const Color(0xFFBAE6FD),
          onTap: () async {
            callCount++;
            await gate.future;
          },
        ),
      ),
    );

    await tester.tap(find.text('Science'));
    await tester.pump();
    await tester.tap(find.text('Science'));
    await tester.tap(find.text('Science'));
    await tester.pump();

    expect(callCount, 1);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('a disabled card is not tappable and shows a coming-soon label', (WidgetTester tester) async {
    int callCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: AdaptiveSubjectCard(
          title: 'Mathematics',
          color: const Color(0xFFFED7AA),
          enabled: false,
          onTap: () async => callCount++,
        ),
      ),
    );

    await tester.tap(find.text('Mathematics'));
    await tester.pump();

    expect(callCount, 0);
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
