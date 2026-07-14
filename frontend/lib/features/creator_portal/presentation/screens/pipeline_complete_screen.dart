/// Creator portal screen shown once the AI pipeline finishes.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// Celebrates a finished render and offers to preview or publish it.
///
/// UI only (Phase 3): "Preview Video" and "Publish for Students" are wired
/// to real actions in Phase 4.
class PipelineCompleteScreen extends StatelessWidget {
  /// Creates the pipeline-completed screen.
  const PipelineCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: const Text('Pipeline Completed!'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: <Widget>[
            const SizedBox(height: AppSpacing.lg),
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.success,
                child: Icon(Icons.celebration_rounded, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Video Generated Successfully',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const DashboardCard(
              child: Column(
                children: <Widget>[
                  _DetailRow(label: 'Book', value: 'Science Std 6'),
                  _DetailRow(label: 'Chapter', value: 'The World of Plants'),
                  _DetailRow(label: 'Topics', value: '18'),
                  _DetailRow(label: 'Duration', value: '08:42'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(label: 'Preview Video', onPressed: () {}),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Publish for Students',
              onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
