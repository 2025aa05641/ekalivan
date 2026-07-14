/// Student portal screen showing one chapter's video and topic list.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/demo_chapter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/video_card.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../widgets/student_bottom_nav.dart';

class _Topic {
  const _Topic({required this.title, required this.unlocked});

  final String title;
  final bool unlocked;
}

const List<_Topic> _placeholderTopics = <_Topic>[
  _Topic(title: 'Plants in Our Surroundings', unlocked: true),
  _Topic(title: 'Parts of a Plant', unlocked: true),
  _Topic(title: 'Photosynthesis', unlocked: true),
  _Topic(title: 'Transpiration', unlocked: false),
  _Topic(title: 'Summary', unlocked: false),
];

/// Chapter titles keyed by id, matching `ChapterListScreen`'s Science set.
const Map<String, String> _chapterSubtitles = <String, String>{
  '1': 'The World of Plants',
  '2': 'Food and Nutrition',
  '3': 'Water',
  '4': 'Heat',
  '5': 'Materials Around Us',
};

/// Shows one chapter's lesson video and its topic breakdown.
///
/// Only Grade 6 Science Chapter 1 ("The World of Plants") is backed by the
/// real pipeline, for either medium (see the roadmap's Scope section — the
/// backend has no per-language narration yet, so both mediums currently
/// produce the same English-narrated video). Every other chapter stays a
/// placeholder.
class ChapterDetailScreen extends ConsumerWidget {
  /// Creates the chapter detail screen for [chapterId].
  const ChapterDetailScreen({
    super.key,
    required this.medium,
    required this.grade,
    required this.subject,
    required this.chapterId,
  });

  /// Medium chosen earlier in the flow.
  final String medium;

  /// Grade chosen earlier in the flow.
  final String grade;

  /// Subject chosen earlier in the flow.
  final String subject;

  /// Chapter id chosen on the previous screen.
  final String chapterId;

  bool get _isRealChapter =>
      (medium == 'english' || medium == 'tamil') && grade == '6' && subject == 'science' && chapterId == '1';

  Future<void> _watchRealLesson(BuildContext context, WidgetRef ref) async {
    final List<VideoJobEntity> cached = await ref.read(videoRepositoryProvider).getOfflineCachedVideos();
    if (!context.mounted) {
      return;
    }
    if (cached.isNotEmpty) {
      context.pushNamed(AppRoute.cachedVideo.routeName, extra: cached.first);
      return;
    }

    await ref.read(videoGenerationProvider.notifier).request(demoChapter);
    if (!context.mounted) {
      return;
    }
    final AsyncValue<VideoJobEntity?> state = ref.read(videoGenerationProvider);
    final VideoJobEntity? job = state.valueOrNull;
    if (job != null) {
      context.pushNamed(AppRoute.generation.routeName, pathParameters: <String, String>{'taskId': job.taskId});
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.error?.toString() ?? 'Unable to start generation.')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String chapterSubtitle = _chapterSubtitles[chapterId] ?? 'Chapter $chapterId';
    return AppScaffold(
      appBar: AppBar(title: Text('Chapter $chapterId')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Text(chapterSubtitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          VideoCard(
            title: chapterSubtitle,
            duration: '08:42',
            onTap: _isRealChapter
                ? () => _watchRealLesson(context, ref)
                : () => ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text('This lesson is being prepared.'))),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Topics in this Chapter', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          for (final _Topic topic in _placeholderTopics)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                topic.unlocked ? Icons.check_circle_rounded : Icons.lock_rounded,
                color: topic.unlocked ? AppColors.success : Colors.grey,
              ),
              title: Text(
                topic.title,
                style: TextStyle(color: topic.unlocked ? null : Colors.grey, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}
