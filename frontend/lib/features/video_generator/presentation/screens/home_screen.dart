/// Landing screen for the child-first chapter selection flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/accessible_text.dart';
import '../../domain/entities/video_job_entity.dart';
import '../../domain/value_objects/video_generation_request_params.dart';
import '../providers/router_provider.dart';
import '../providers/video_generation_provider.dart';
import '../widgets/adaptive_subject_card.dart';
import '../widgets/responsive_layout_gate.dart';

/// Stand-in for a chapter catalog, which does not exist yet: the backend has
/// no endpoint to list available chapters, only to generate from a known
/// file path. This is the one chapter file present in every checkout
/// (it backs the backend's own test suite), used here until a real
/// chapter-selection flow exists.
const VideoGenerationRequestParams _scienceDemoChapter = VideoGenerationRequestParams(
  classLevel: '6',
  subject: 'Science',
  chapterTitle: 'The World of Plants',
  fileStoragePath: 'tests/fixtures/sample_chapter.txt',
);

/// Provides the first, intentionally shallow navigation level.
class HomeScreen extends StatelessWidget {
  /// Creates the home screen.
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn with Videos'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.video_library),
            tooltip: 'My Videos',
            onPressed: () => context.pushNamed(AppRoute.myVideos.routeName),
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Creator Portal',
            onPressed: () => context.pushNamed(AppRoute.adminLogin.routeName),
          ),
        ],
      ),
      body: const SafeArea(
        child: ResponsiveLayoutGate(
          phone: _SubjectBody(crossAxisCount: 1),
          tablet: _SubjectBody(crossAxisCount: 2),
        ),
      ),
    );
  }
}

class _SubjectBody extends ConsumerWidget {
  const _SubjectBody({required this.crossAxisCount});

  final int crossAxisCount;

  Future<void> _generateAndNavigate(
    BuildContext context,
    WidgetRef ref,
    VideoGenerationRequestParams params,
  ) async {
    await ref.read(videoGenerationProvider.notifier).request(params);
    if (!context.mounted) {
      return;
    }
    final AsyncValue<VideoJobEntity?> state = ref.read(videoGenerationProvider);
    final VideoJobEntity? job = state.valueOrNull;
    if (job != null) {
      context.goNamed(AppRoute.generation.routeName, pathParameters: <String, String>{'taskId': job.taskId});
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.error?.toString() ?? 'Unable to start generation.')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AccessibleText('Choose your subject', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          const AccessibleText('Pick a chapter and watch a lesson made for you.'),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.5,
              children: <Widget>[
                AdaptiveSubjectCard(
                  title: 'Science',
                  color: const Color(0xFFBAE6FD),
                  onTap: () => _generateAndNavigate(context, ref, _scienceDemoChapter),
                ),
                AdaptiveSubjectCard(
                  title: 'Mathematics',
                  color: const Color(0xFFFED7AA),
                  enabled: false,
                  onTap: () async {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
