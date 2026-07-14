/// Student portal screen for choosing English or Tamil medium.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/student_bottom_nav.dart';

/// One medium option shown on this screen.
class _Medium {
  const _Medium({required this.id, required this.icon, required this.title, required this.subtitle, required this.color});

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

const List<_Medium> _mediums = <_Medium>[
  _Medium(
    id: 'english',
    icon: Icons.menu_book_rounded,
    title: 'English Medium',
    subtitle: 'Learn in English',
    color: AppColors.primaryBlue,
  ),
  _Medium(id: 'tamil', icon: Icons.menu_book_rounded, title: 'தமிழ் வழி', subtitle: 'Tamil Medium', color: AppColors.success),
];

/// The Student portal's home screen: choose a teaching medium.
class MediumSelectionScreen extends StatelessWidget {
  /// Creates the medium selection screen.
  const MediumSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Choose Your Medium')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          for (final _Medium medium in _mediums) ...<Widget>[
            InkWell(
              onTap: () => context.goNamed(
                AppRoute.studentClass.routeName,
                pathParameters: <String, String>{'medium': medium.id},
              ),
              child: DashboardCard(
                child: Row(
                  children: <Widget>[
                    CircleAvatar(radius: 24, backgroundColor: medium.color.withValues(alpha: 0.12), child: Icon(medium.icon, color: medium.color)),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(medium.title, style: Theme.of(context).textTheme.titleLarge),
                          Text(medium.subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
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
