/// Student portal screen listing a subject's chapters.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';
import '../widgets/student_bottom_nav.dart';

class _Chapter {
  const _Chapter({required this.id, required this.icon, required this.title, required this.subtitle});

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
}

const List<_Chapter> _scienceGrade6Chapters = <_Chapter>[
  _Chapter(id: '1', icon: Icons.eco_rounded, title: 'Chapter 1', subtitle: 'The World of Plants'),
  _Chapter(id: '2', icon: Icons.restaurant_rounded, title: 'Chapter 2', subtitle: 'Food and Nutrition'),
  _Chapter(id: '3', icon: Icons.water_drop_rounded, title: 'Chapter 3', subtitle: 'Water'),
  _Chapter(id: '4', icon: Icons.thermostat_rounded, title: 'Chapter 4', subtitle: 'Heat'),
  _Chapter(id: '5', icon: Icons.terrain_rounded, title: 'Chapter 5', subtitle: 'Materials Around Us'),
];

const List<_Chapter> _genericChapters = <_Chapter>[
  _Chapter(id: '1', icon: Icons.auto_stories_rounded, title: 'Chapter 1', subtitle: 'Introduction'),
  _Chapter(id: '2', icon: Icons.school_rounded, title: 'Chapter 2', subtitle: 'Core Concepts'),
  _Chapter(id: '3', icon: Icons.explore_rounded, title: 'Chapter 3', subtitle: 'Advanced Topics'),
];

/// Lists a subject's chapters, each leading to its lesson video.
class ChapterListScreen extends ConsumerWidget {
  /// Creates the chapter list screen for [medium], [grade], and [subject].
  const ChapterListScreen({super.key, required this.medium, required this.grade, required this.subject});

  /// Medium chosen earlier in the flow.
  final String medium;

  /// Grade chosen earlier in the flow.
  final String grade;

  /// Subject chosen earlier in the flow.
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(recentJobsProvider).valueOrNull ?? const [];
    final List<_Chapter> chapters = jobs
        .where((job) =>
            job.status == 'COMPLETED' &&
            job.classLevel == grade &&
            job.subject.toLowerCase() == subject.toLowerCase())
        .map((job) => _Chapter(
              id: job.taskId,
              icon: Icons.play_lesson_rounded,
              title: job.chapterTitle,
              subtitle: 'AI-generated video lesson',
            ))
        .toList();
    final String gradeLabel = 'Grade $grade';
    final String subjectLabel = subject[0].toUpperCase() + subject.substring(1).replaceAll('-', ' ');
    return AppScaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
        title: Text(gradeLabel),
      ),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: <Widget>[
            Container(
              color: Colors.white,
              child: TabBar(
                labelColor: AppColors.primaryBlue,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppColors.primaryBlue,
                indicatorWeight: 3,
                tabs: <Widget>[
                  Tab(text: subjectLabel),
                  const Tab(text: 'About'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  chapters.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                const Text(
                                  'Chapters for this subject are coming soon.',
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: <Widget>[
                            for (final _Chapter chapter in chapters) ...<Widget>[
                              _ChapterRow(
                                chapter: chapter,
                                onWatch: () => context.pushNamed(
                                  AppRoute.studentChapterDetail.routeName,
                                  pathParameters: <String, String>{
                                    'medium': medium,
                                    'grade': grade,
                                    'subject': subject,
                                    'chapterId': chapter.id,
                                  },
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                            ],
                          ],
                        ),
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        'Lessons made for you, one chapter at a time.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.chapter, required this.onWatch});

  final _Chapter chapter;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(chapter.icon, color: AppColors.primaryBlue, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  chapter.title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                Text(
                  chapter.subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Semantics(
            button: true,
            label: 'Watch ${chapter.title} lesson',
            child: GestureDetector(
              onTap: onWatch,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Watch Lesson',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
