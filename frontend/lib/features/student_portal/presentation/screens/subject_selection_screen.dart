/// Student portal screen for choosing a subject within a chosen class.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/student_bottom_nav.dart';

class _Subject {
  const _Subject({required this.id, required this.icon, required this.title, required this.color});

  final String id;
  final IconData icon;
  final String title;
  final Color color;
}

const List<_Subject> _subjects = <_Subject>[
  _Subject(id: 'tamil', icon: Icons.translate_rounded, title: 'Tamil', color: AppColors.success),
  _Subject(id: 'english', icon: Icons.abc_rounded, title: 'English', color: AppColors.primaryBlue),
  _Subject(id: 'mathematics', icon: Icons.functions_rounded, title: 'Mathematics', color: AppColors.warning),
  _Subject(id: 'science', icon: Icons.science_rounded, title: 'Science', color: AppColors.primaryPurple),
  _Subject(id: 'social-science', icon: Icons.public_rounded, title: 'Social Science', color: AppColors.danger),
];

/// Subject picker shown after choosing a medium and class.
class SubjectSelectionScreen extends StatelessWidget {
  /// Creates the subject selection screen for [medium] and [grade].
  const SubjectSelectionScreen({super.key, required this.medium, required this.grade});

  /// Medium chosen earlier in the flow.
  final String medium;

  /// Grade chosen earlier in the flow.
  final String grade;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: Text(medium == 'tamil' ? 'தமிழ் வழி' : 'English Medium')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text('Choose Subject', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          for (final _Subject subject in _subjects) ...<Widget>[
            InkWell(
              onTap: () => context.goNamed(
                AppRoute.studentChapters.routeName,
                pathParameters: <String, String>{'medium': medium, 'grade': grade, 'subject': subject.id},
              ),
              child: DashboardCard(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: subject.color.withValues(alpha: 0.12),
                      child: Icon(subject.icon, color: subject.color),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: Text(subject.title, style: Theme.of(context).textTheme.titleMedium)),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}
