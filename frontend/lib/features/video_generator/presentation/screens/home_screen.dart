/// Landing screen for the child-first chapter selection flow.
import 'package:flutter/material.dart';

import '../../../../core/widgets/accessible_text.dart';
import '../widgets/adaptive_subject_card.dart';
import '../widgets/responsive_layout_gate.dart';

/// Provides the first, intentionally shallow navigation level.
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Learn with Videos')),
      body: SafeArea(
        child: ResponsiveLayoutGate(
          phone: _SubjectBody(crossAxisCount: 1),
          tablet: _SubjectBody(crossAxisCount: 2),
        ),
      ),
    );
  }
}

class _SubjectBody extends StatelessWidget {
  const _SubjectBody({required this.crossAxisCount});

  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AccessibleText('Choose your subject', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const AccessibleText('Pick a chapter and watch a lesson made for you.'),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: <Widget>[
                AdaptiveSubjectCard(title: 'Science', color: const Color(0xFFBAE6FD), onTap: () {}),
                AdaptiveSubjectCard(title: 'Mathematics', color: const Color(0xFFFED7AA), onTap: () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
