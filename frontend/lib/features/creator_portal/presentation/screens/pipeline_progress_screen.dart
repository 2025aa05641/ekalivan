/// Creator portal screen showing the 8-step AI pipeline's live progress.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/accessible_error_widget.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/domain/entities/recent_job_entity.dart';
import '../../../video_generator/domain/entities/video_status_update_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';

/// One named stage in the backend's LangGraph content-generation pipeline.
const List<String> pipelineStageNames = <String>[
  'Textbook Parsing',
  'Curriculum Mapping',
  'Lesson Planner',
  'Teacher Script',
  'Storyboard',
  'Narration (TTS)',
  'Video Rendering',
  'Publishing',
];

/// Shows the 8-step AI pipeline for the job identified by [taskId].
class PipelineProgressScreen extends ConsumerStatefulWidget {
  /// Creates the pipeline progress screen for [taskId].
  const PipelineProgressScreen({super.key, required this.taskId});

  /// Job identifier returned when generation was accepted.
  final String taskId;

  @override
  ConsumerState<PipelineProgressScreen> createState() => _PipelineProgressScreenState();
}

class _PipelineProgressScreenState extends ConsumerState<PipelineProgressScreen> {
  bool _completionHandled = false;

  String get taskId => widget.taskId;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<VideoStatusUpdateEntity>>(videoProgressProvider(taskId),
        (AsyncValue<VideoStatusUpdateEntity>? previous, AsyncValue<VideoStatusUpdateEntity> next) {
      next.whenData((VideoStatusUpdateEntity update) {
        if (_completionHandled || update.status != 'COMPLETED' || update.videoUrl == null) {
          return;
        }
        _completionHandled = true;
        ref.invalidate(recentJobsProvider);
        ref.invalidate(myVideosProvider);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          context.goNamed(
            AppRoute.adminComplete.routeName,
            pathParameters: <String, String>{'taskId': taskId},
          );
        });
      });
    });
    final AsyncValue<VideoStatusUpdateEntity> progress = ref.watch(videoProgressProvider(taskId));
    final AsyncValue<List<RecentJobEntity>> recentJobsAsync = ref.watch(recentJobsProvider);

    final RecentJobEntity? realJob = recentJobsAsync.maybeWhen(
      data: (List<RecentJobEntity> jobs) {
        try {
          return jobs.firstWhere((RecentJobEntity j) => j.taskId == taskId);
        } catch (_) {
          return null;
        }
      },
      orElse: () => null,
    );

    final String title = realJob != null
        ? 'AI Pipeline - ${realJob.subject} ${realJob.classLevel}'
        : switch (taskId) {
            'mock-science-6' => 'AI Pipeline - Science Std 6',
            'mock-maths-7' => 'AI Pipeline - Maths Std 7',
            'mock-tamil-8' => 'AI Pipeline - Tamil Std 8',
            'mock-social-6' => 'AI Pipeline - Social Science Std 6',
            _ => 'AI Pipeline',
          };

    final String subtitle = realJob != null
        ? realJob.chapterTitle
        : switch (taskId) {
            'mock-science-6' => 'The World of Plants',
            'mock-maths-7' => 'Integers',
            'mock-tamil-8' => 'எழுத்து - 1',
            'mock-social-6' => 'Our Earth',
            _ => 'Generating video...',
          };

    final IconData icon = realJob != null
        ? (realJob.subject.toLowerCase().contains('science')
            ? Icons.eco_rounded
            : realJob.subject.toLowerCase().contains('math')
                ? Icons.calculate_rounded
                : realJob.subject.toLowerCase().contains('tamil')
                    ? Icons.translate_rounded
                    : Icons.public_rounded)
        : switch (taskId) {
            'mock-science-6' => Icons.eco_rounded,
            'mock-maths-7' => Icons.calculate_rounded,
            'mock-tamil-8' => Icons.translate_rounded,
            _ => Icons.public_rounded,
          };

    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: Text(title),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Admin Home',
            onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName),
          ),
        ],
      ),
      body: progress.when(
        data: (VideoStatusUpdateEntity update) => _PipelineStepList(
          taskId: taskId,
          update: update,
          subtitle: subtitle,
          icon: icon,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: AccessibleErrorWidget(
            message: error.toString(),
            onRetry: () => ref.invalidate(videoProgressProvider(taskId)),
          ),
        ),
      ),
    );
  }
}

class _PipelineStepList extends StatelessWidget {
  const _PipelineStepList({
    required this.taskId,
    required this.update,
    required this.subtitle,
    required this.icon,
  });

  final String taskId;
  final VideoStatusUpdateEntity update;
  final String subtitle;
  final IconData icon;

  /// Maps the current stage name to its 0-based index so we can highlight it.
  int get _currentStageIndex {
    final String node = update.currentNode;
    final int idx = pipelineStageNames.indexWhere(
      (String s) => s.toLowerCase() == node.toLowerCase(),
    );
    if (idx >= 0) return idx;
    // Fallback: derive from progress percentage.
    return (update.progress / 100 * pipelineStageNames.length).floor().clamp(0, pipelineStageNames.length - 1);
  }

  @override
  Widget build(BuildContext context) {
    final bool isFailed = update.status == 'FAILED';

    final int completedSteps = update.status == 'COMPLETED'
        ? pipelineStageNames.length
        : _currentStageIndex;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.md),
      children: <Widget>[
        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ],
          ),
        ),
        // Pipeline steps
        for (int i = 0; i < pipelineStageNames.length; i++)
          _PipelineStepTile(
            stepNumber: i + 1,
            label: pipelineStageNames[i],
            status: update.status == 'COMPLETED'
                ? _StepStatus.completed
                : i < completedSteps
                    ? _StepStatus.completed
                    : i == completedSteps
                        ? (isFailed ? _StepStatus.error : _StepStatus.current)
                        : _StepStatus.pending,
            subtitle: update.status == 'COMPLETED'
                ? 'Completed'
                : i < completedSteps
                    ? 'Completed'
                    : i == completedSteps
                        ? (isFailed ? 'Failed' : 'Processing')
                        : 'Queued',
            errorMessage: i == completedSteps && isFailed ? update.errorMessage : null,
            onTap: () => _handleTap(context, i, completedSteps),
          ),
      ],
    );
  }

  void _handleTap(BuildContext context, int stageIndex, int completedSteps) {
    if (update.status == 'COMPLETED') {
      context.goNamed(
        AppRoute.adminComplete.routeName,
        pathParameters: <String, String>{'taskId': taskId},
      );
      return;
    }
    // Completed stages → show detail sheet
    if (update.status == 'COMPLETED' || stageIndex < completedSteps) {
      _showStageDetail(context, stageIndex);
      return;
    }
    // Currently active stage → navigate to rendering screen
    if (stageIndex == completedSteps) {
      context.goNamed(
        AppRoute.adminRendering.routeName,
        pathParameters: <String, String>{'taskId': taskId},
      );
      return;
    }
  }

  void _showStageDetail(BuildContext context, int stageIndex) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StageDetailSheet(
        stageIndex: stageIndex,
        stageName: pipelineStageNames[stageIndex],
        update: update,
      ),
    );
  }
}

enum _StepStatus { completed, current, pending, error }

class _PipelineStepTile extends StatelessWidget {
  const _PipelineStepTile({
    required this.stepNumber,
    required this.label,
    required this.status,
    required this.subtitle,
    this.errorMessage,
    this.onTap,
  });

  final int stepNumber;
  final String label;
  final _StepStatus status;
  final String subtitle;
  final String? errorMessage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (status) {
      _StepStatus.completed => AppColors.success,
      _StepStatus.current => AppColors.primaryBlue,
      _StepStatus.pending => Colors.grey.shade400,
      _StepStatus.error => Colors.red.shade400,
    };

    final Widget trailingIndicator = switch (status) {
      _StepStatus.completed => const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
      _StepStatus.current => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
        ),
      _StepStatus.pending => Icon(Icons.radio_button_unchecked_rounded, color: color, size: 22),
      _StepStatus.error => const Icon(Icons.error_outline_rounded, color: Colors.red, size: 22),
    };

    // Show chevron on completed stages to hint they are tappable.
    final bool isCompletedAndTappable = status == _StepStatus.completed && onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: status == _StepStatus.current
              ? AppColors.primaryBlue.withValues(alpha: 0.06)
              : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status == _StepStatus.current ? AppColors.primaryBlue.withValues(alpha: 0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$stepNumber',
                style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: status == _StepStatus.pending ? Colors.grey : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                  if (errorMessage != null) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 11, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ),
            if (isCompletedAndTappable)
              const Icon(Icons.chevron_right_rounded, color: AppColors.success, size: 20)
            else
              trailingIndicator,
          ],
        ),
      ),
    );
  }
}

/// Bottom-sheet showing the AI output for a specific completed pipeline stage.
class _StageDetailSheet extends StatelessWidget {
  const _StageDetailSheet({
    required this.stageIndex,
    required this.stageName,
    required this.update,
  });

  final int stageIndex;
  final String stageName;
  final VideoStatusUpdateEntity update;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.3,
      builder: (_, ScrollController sc) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: <Widget>[
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${stageIndex + 1}',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          stageName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const Text(
                          'Completed ✓',
                          style: TextStyle(color: AppColors.success, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: ListView(
                controller: sc,
                padding: const EdgeInsets.all(20),
                children: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (stageIndex) {
      // Stage 0: Lesson Planner — show parsed markdown
      case 0:
        final String? md = update.markdownContent;
        if (md == null || md.isEmpty) return <Widget>[_emptyCard('No parsed content available.')];
        return <Widget>[
          _sectionHeader('Parsed Book Content'),
          _codeCard(md.length > 2000 ? '${md.substring(0, 2000)}\n\n... (truncated)' : md),
        ];

      // Stage 1: Teacher — show structured sections
      case 1:
      case 2:
      case 3:
        final List<Map<String, Object?>>? secs = update.sections;
        if (secs == null || secs.isEmpty) return <Widget>[_emptyCard('No sections available.')];
        return <Widget>[
          _sectionHeader('Curriculum Sections (${secs.length})'),
          for (final Map<String, Object?> s in secs) _sectionCard(s['title'] as String? ?? '', s['content'] as String? ?? ''),
        ];

      // Stage 2: Storyboard — show visual beats
      case 4:
        final List<Map<String, Object?>>? beats = update.storyboardBeats;
        if (beats == null || beats.isEmpty) return <Widget>[_emptyCard('No storyboard beats available.')];
        return <Widget>[
          _sectionHeader('Storyboard (${beats.length} beats)'),
          for (int i = 0; i < beats.length; i++) _beatCard(i + 1, beats[i], showAudio: false),
        ];

      // Stage 3: Narration (TTS) — show narrated beats with timing
      case 5:
        final List<Map<String, Object?>>? beats = update.narratedBeats;
        if (beats == null || beats.isEmpty) return <Widget>[_emptyCard('No narrated beats available.')];
        return <Widget>[
          _sectionHeader('Narrated Beats (${beats.length})'),
          for (int i = 0; i < beats.length; i++) _beatCard(i + 1, beats[i], showAudio: true),
        ];

      default:
        return <Widget>[_emptyCard('Details not available for this stage.')];
    }
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.primaryBlue)),
      );

  Widget _emptyCard(String message) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
        child: Text(message, style: const TextStyle(color: Colors.grey)),
      );

  Widget _codeCard(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.5)),
      );

  Widget _sectionCard(String title, String content) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 6),
            Text(content, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5)),
          ],
        ),
      );

  Widget _beatCard(int idx, Map<String, Object?> beat, {required bool showAudio}) {
    final double duration = (beat['duration_seconds'] as num?)?.toDouble() ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('Beat $idx', style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.w600, fontSize: 11)),
              ),
              const SizedBox(width: 8),
              Text('${duration.toStringAsFixed(1)}s', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            beat['narration'] as String? ?? '',
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), height: 1.4),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.image_rounded, size: 12, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    beat['visual_prompt'] as String? ?? '',
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (showAudio && beat['audio_path'] != null) ...<Widget>[
            const SizedBox(height: 6),
            Row(
              children: <Widget>[
                const Icon(Icons.audio_file_rounded, size: 12, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Audio generated', style: TextStyle(fontSize: 11, color: AppColors.success)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
