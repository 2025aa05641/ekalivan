/// Student portal screen for choosing a grade within a chosen medium.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/student_bottom_nav.dart';

/// Grade picker shown after choosing a medium.
class ClassSelectionScreen extends StatelessWidget {
  /// Creates the class selection screen for [medium].
  const ClassSelectionScreen({super.key, required this.medium});

  /// Medium chosen on the previous screen (`english` or `tamil`).
  final String medium;

  @override
  Widget build(BuildContext context) {
    final String mediumLabel = medium == 'tamil' ? 'Tamil Medium' : 'English Medium';
    return AppScaffold(
      appBar: AppBar(title: Text(mediumLabel)),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Choose Your Class', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.1,
                children: <Widget>[
                  for (int grade = 1; grade <= 12; grade++)
                    _GradeTile(
                      grade: grade,
                      onTap: () => context.goNamed(
                        AppRoute.studentSubject.routeName,
                        pathParameters: <String, String>{'medium': medium, 'grade': '$grade'},
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradeTile extends StatelessWidget {
  const _GradeTile({required this.grade, required this.onTap});

  final int grade;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Grade $grade',
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.school_rounded, color: AppColors.primaryBlue),
              const SizedBox(height: AppSpacing.xs),
              Text('Grade $grade', style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ),
      ),
    );
  }
}
