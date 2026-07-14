/// Rounded chapter card with a thumbnail, title, and watch-lesson action.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'dashboard_card.dart';

/// Chapter row shown in the student portal's chapter list.
class ChapterCard extends StatelessWidget {
  /// Creates the chapter card.
  const ChapterCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onWatch,
  });

  /// Chapter title, e.g. "Chapter 1".
  final String title;

  /// Chapter subtitle, e.g. "The World of Plants".
  final String subtitle;

  /// Leading icon representing the chapter.
  final IconData icon;

  /// Invoked when "Watch Lesson" is tapped.
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.background,
            child: Icon(icon, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            button: true,
            label: 'Watch $title lesson',
            child: TextButton(
              onPressed: onWatch,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              child: const Text('Watch Lesson'),
            ),
          ),
        ],
      ),
    );
  }
}
