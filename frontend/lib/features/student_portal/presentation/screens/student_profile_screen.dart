/// Profile screen for the student portal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../providers/student_auth_provider.dart';
import '../widgets/student_bottom_nav.dart';

/// Shows the student's profile or a guest indicator.
class StudentProfileScreen extends ConsumerWidget {
  /// Creates the profile screen.
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isGuest = ref.watch(isGuestProvider);
    
    return AppScaffold(
      appBar: AppBar(title: const Text('Profile')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.profile),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isGuest ? Colors.grey.shade200 : AppColors.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isGuest ? Icons.person_outline_rounded : Icons.school_rounded,
                size: 48,
                color: isGuest ? Colors.grey : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isGuest ? 'Guest User' : 'Student Name',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            isGuest ? 'Sign in to save your progress' : 'Grade 6 • Science',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 48),
          _ProfileRow(icon: Icons.settings_rounded, title: 'Settings', onTap: () {}),
          const SizedBox(height: 16),
          _ProfileRow(icon: Icons.help_outline_rounded, title: 'Help & Support', onTap: () {}),
          const SizedBox(height: 16),
          _ProfileRow(icon: Icons.logout_rounded, title: isGuest ? 'Sign In' : 'Sign Out', onTap: () {}),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.title, required this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, color: AppColors.primaryBlue),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
