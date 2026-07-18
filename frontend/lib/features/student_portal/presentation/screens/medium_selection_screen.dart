/// Student portal screen for choosing English or Tamil medium.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/student_bottom_nav.dart';

/// One medium option shown on this screen.
class _Medium {
  const _Medium({required this.id, required this.label, required this.subtitle, required this.avatarText, required this.color});

  final String id;
  final String label;
  final String subtitle;
  final String avatarText;
  final Color color;
}

const List<_Medium> _mediums = <_Medium>[
  _Medium(
    id: 'english',
    label: 'English Medium',
    subtitle: 'Learn in English',
    avatarText: 'A',
    color: AppColors.primaryBlue,
  ),
  _Medium(
    id: 'tamil',
    label: 'தமிழ் வழி',
    subtitle: 'Tamil Medium',
    avatarText: 'அ',
    color: AppColors.success,
  ),
];

/// The Student portal's home screen: choose a teaching medium.
class MediumSelectionScreen extends StatelessWidget {
  /// Creates the medium selection screen.
  const MediumSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: const Text('Choose Medium'),
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          for (final _Medium medium in _mediums) ...<Widget>[
            _MediumCard(
              medium: medium,
              onTap: () => context.pushNamed(
                AppRoute.studentClass.routeName,
                pathParameters: <String, String>{'medium': medium.id},
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _MediumCard extends StatelessWidget {
  const _MediumCard({required this.medium, required this.onTap});

  final _Medium medium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Row(
            children: <Widget>[
              // Avatar with letter
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: medium.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  medium.avatarText,
                  style: TextStyle(
                    color: medium.color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      medium.label,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      medium.subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
