import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:textbook_video_learning/features/video_generator/presentation/widgets/responsive_layout_gate.dart';

void main() {
  testWidgets('uses tablet body at the 600px architecture breakpoint', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(600, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(
        home: ResponsiveLayoutGate(phone: Text('phone'), tablet: Text('tablet')),
      ),
    );

    expect(find.text('tablet'), findsOneWidget);
    expect(find.text('phone'), findsNothing);
  });
}
