/// Student portal screen for choosing a subject within a chosen class.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/student_bottom_nav.dart';

class _Subject {
  const _Subject({required this.id, required this.icon, required this.title, required this.subtitle, required this.color});

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

const List<_Subject> _subjects = <_Subject>[
  _Subject(id: 'tamil', icon: Icons.translate_rounded, title: 'தமிழ்', subtitle: 'Tamil', color: AppColors.success),
  _Subject(id: 'english', icon: Icons.abc_rounded, title: 'English', subtitle: 'English', color: AppColors.primaryBlue),
  _Subject(id: 'mathematics', icon: Icons.functions_rounded, title: 'Mathematics', subtitle: 'Mathematics', color: AppColors.warning),
  _Subject(id: 'science', icon: Icons.science_rounded, title: 'Science', subtitle: 'Science', color: AppColors.primaryPurple),
  _Subject(
    id: 'social-science',
    icon: Icons.public_rounded,
    title: 'Social Science',
    subtitle: 'Social Science',
    color: AppColors.danger,
  ),
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
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(medium == 'tamil' ? 'தமிழ் வழி' : 'English Medium'),
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text(
            'Choose Subject',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final _Subject subject in _subjects) ...<Widget>[
            _SubjectCard(
              subject: subject,
              onTap: () => context.pushNamed(
                AppRoute.studentChapters.routeName,
                pathParameters: <String, String>{'medium': medium, 'grade': grade, 'subject': subject.id},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject, required this.onTap});

  final _Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: subject.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(subject.icon, color: subject.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      subject.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    if (subject.subtitle != subject.title)
                      Text(
                        subject.subtitle,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
