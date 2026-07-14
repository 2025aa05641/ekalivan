/// Creator portal screen for the pipeline's Video Rendering step in detail.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// Detail view for the pipeline's "Video Rendering" step, with a progress
/// bar and per-topic status.
///
/// UI only (Phase 3): progress and timing are mock values, replaced with
/// the real job's live status in Phase 4.
class RenderingProgressScreen extends StatelessWidget {
  /// Creates the rendering progress screen.
  const RenderingProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminPipeline.routeName)),
        title: const Text('Pipeline - Step 5'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          const Text('Video Rendering', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: AppSpacing.lg),
          DashboardCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.movie_creation_rounded, size: 56, color: AppColors.primaryBlue),
                      const SizedBox(height: AppSpacing.sm),
                      Text('Rendering Video', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: AppSpacing.xs),
                      const Text(
                        'Please wait while we generate the video...',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  child: LinearProgressIndicator(value: 0.65, minHeight: 8, backgroundColor: AppColors.border),
                ),
                const SizedBox(height: AppSpacing.md),
                const _StatRow(label: 'Estimated Time Remaining', value: '00:03:45'),
                const _StatRow(label: 'Current Topic', value: 'Photosynthesis'),
                const _StatRow(label: 'Progress', value: '12 / 18 Topics'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'You will be notified once the video is ready.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: AppSpacing.md),
          PrimaryButton(
            label: 'Continue When Ready',
            onPressed: () => context.goNamed(AppRoute.adminComplete.routeName),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

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
