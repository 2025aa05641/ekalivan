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
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(medium == 'tamil' ? 'தமிழ் வழி' : 'English Medium'),
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Choose Your Class',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: 12,
                itemBuilder: (BuildContext context, int index) {
                  final int grade = index + 1;
                  return _GradeTile(
                    grade: grade,
                    onTap: () => context.pushNamed(
                      AppRoute.studentSubject.routeName,
                      pathParameters: <String, String>{'medium': medium, 'grade': '$grade'},
                    ),
                  );
                },
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
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: AppColors.primaryBlue, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  'Grade $grade',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
