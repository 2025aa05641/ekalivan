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
  _Topic(title: '1. Plants in Our Surroundings', unlocked: true),
  _Topic(title: '2. Parts of a Plant', unlocked: true),
  _Topic(title: '3. Photosynthesis', unlocked: true),
  _Topic(title: '4. Transpiration', unlocked: false),
  _Topic(title: '5. Summary', unlocked: false),
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
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text('Chapter $chapterId'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(22),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              chapterSubtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // Video player card
          VideoCard(
            title: chapterSubtitle,
            duration: '06:42',
            onTap: _isRealChapter
                ? () => _watchRealLesson(context, ref)
                : () => ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('This lesson is being prepared.'))),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Topics in this Chapter',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Topics list
          Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
            ),
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _placeholderTopics.length; i++) ...<Widget>[
                  _TopicTile(topic: _placeholderTopics[i]),
                  if (i < _placeholderTopics.length - 1)
                    const Divider(height: 1, indent: 56, endIndent: 16, color: AppColors.border),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic});

  final _Topic topic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: <Widget>[
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: topic.unlocked
                  ? AppColors.success.withValues(alpha: 0.12)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              topic.unlocked ? Icons.check_rounded : Icons.lock_outline_rounded,
              color: topic.unlocked ? AppColors.success : Colors.grey,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            topic.title,
            style: TextStyle(
              color: topic.unlocked ? const Color(0xFF0F172A) : Colors.grey,
              fontWeight: topic.unlocked ? FontWeight.w600 : FontWeight.w400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
