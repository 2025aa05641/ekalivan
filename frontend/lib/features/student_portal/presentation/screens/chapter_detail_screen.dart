/// Student portal screen showing one chapter's video and topic list.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/video_card.dart';
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
/// The video itself is placeholder content in this phase — real playback
/// is wired in a later phase, reusing the pipeline already built for the
/// Creator portal.
class ChapterDetailScreen extends StatelessWidget {
  /// Creates the chapter detail screen for [chapterId].
  const ChapterDetailScreen({super.key, required this.chapterId});

  /// Chapter id chosen on the previous screen.
  final String chapterId;

  @override
  Widget build(BuildContext context) {
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
            onTap: () => ScaffoldMessenger.of(
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
