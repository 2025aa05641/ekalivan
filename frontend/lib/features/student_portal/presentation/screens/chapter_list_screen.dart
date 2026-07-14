/// Student portal screen listing a subject's chapters.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/chapter_card.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
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

/// Lists a subject's chapters, each leading to its lesson video.
///
/// Only Grade 6 Science's Chapter 1 ("The World of Plants") is backed by
/// the real pipeline (see the roadmap's Scope section); every other
/// chapter here is placeholder content.
class ChapterListScreen extends StatelessWidget {
  /// Creates the chapter list screen for [medium], [grade], and [subject].
  const ChapterListScreen({super.key, required this.medium, required this.grade, required this.subject});

  /// Medium chosen earlier in the flow.
  final String medium;

  /// Grade chosen earlier in the flow.
  final String grade;

  /// Subject chosen earlier in the flow.
  final String subject;

  @override
  Widget build(BuildContext context) {
    final bool isScience = subject == 'science';
    final List<_Chapter> chapters = isScience ? _scienceGrade6Chapters : const <_Chapter>[];
    return AppScaffold(
      appBar: AppBar(title: Text('Grade $grade')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.home),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: <Widget>[
            const TabBar(
              labelColor: AppColors.primaryBlue,
              indicatorColor: AppColors.primaryBlue,
              tabs: <Widget>[Tab(text: 'Chapters'), Tab(text: 'About')],
            ),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  chapters.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.md),
                            child: Text('Chapters for this subject are coming soon.', style: TextStyle(color: Colors.grey)),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          children: <Widget>[
                            for (final _Chapter chapter in chapters) ...<Widget>[
                              ChapterCard(
                                title: chapter.title,
                                subtitle: chapter.subtitle,
                                icon: chapter.icon,
                                onWatch: () => context.goNamed(
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
                      child: Text('Lessons made for you, one chapter at a time.', style: TextStyle(color: Colors.grey)),
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
