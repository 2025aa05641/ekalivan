/// Creator portal screen for selecting a textbook PDF and its target class.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/demo_chapter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/dashboard_card.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';

/// Upload-a-book screen: choose a PDF, then its medium and class.
///
/// The file picker, medium, and class are still mocked — there is no real
/// upload or chapter-catalog endpoint (see [demoChapter]) — but
/// "Upload & Process" now starts a real backend generation job and carries
/// its task ID through the rest of the pipeline screens.
class UploadBookScreen extends ConsumerStatefulWidget {
  /// Creates the upload book screen.
  const UploadBookScreen({super.key});

  @override
  ConsumerState<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends ConsumerState<UploadBookScreen> {
  String? _selectedFileName = 'Science_6th_Standard.pdf';
  String _medium = 'English';
  String _grade = 'Grade 6';
  bool _isSubmitting = false;

  Future<void> _uploadAndProcess() async {
    setState(() => _isSubmitting = true);
    await ref.read(videoGenerationProvider.notifier).request(demoChapter);
    if (!mounted) {
      return;
    }
    setState(() => _isSubmitting = false);
    final AsyncValue<VideoJobEntity?> state = ref.read(videoGenerationProvider);
    final VideoJobEntity? job = state.valueOrNull;
    if (job != null) {
      context.goNamed(AppRoute.adminPipeline.routeName, pathParameters: <String, String>{'taskId': job.taskId});
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(state.error?.toString() ?? 'Unable to start generation.')));
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName)),
        title: const Text('Upload New Book'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          DottedDropZone(
            hasFile: _selectedFileName != null,
            onChooseFile: () => setState(() => _selectedFileName = 'Science_6th_Standard.pdf'),
          ),
          if (_selectedFileName != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            DashboardCard(
              child: Row(
                children: <Widget>[
                  const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(_selectedFileName!, style: Theme.of(context).textTheme.titleMedium),
                        Text('12.4 MB', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedFileName = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          Text('Select Medium', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _Dropdown(value: _medium, options: const <String>['English', 'Tamil'], onChanged: (String v) => setState(() => _medium = v)),
          const SizedBox(height: AppSpacing.md),
          Text('Select Class', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _Dropdown(
            value: _grade,
            options: const <String>['Grade 6', 'Grade 7', 'Grade 8'],
            onChanged: (String v) => setState(() => _grade = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Upload & Process',
            loading: _isSubmitting,
            onPressed: _selectedFileName == null || _isSubmitting ? null : _uploadAndProcess,
          ),
        ],
      ),
    );
  }
}

/// Dashed drag-and-drop zone prompting the creator to pick a PDF.
class DottedDropZone extends StatelessWidget {
  /// Creates the drop zone.
  const DottedDropZone({super.key, required this.hasFile, required this.onChooseFile});

  /// Whether a file has already been selected (dims the prompt).
  final bool hasFile;

  /// Invoked when "Choose File" is tapped.
  final VoidCallback onChooseFile;

  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Column(
          children: <Widget>[
            Icon(Icons.cloud_upload_outlined, size: 48, color: AppColors.primaryBlue.withValues(alpha: hasFile ? 0.4 : 1)),
            const SizedBox(height: AppSpacing.sm),
            const Text('Drag & drop your PDF here'),
            const Text('or', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onChooseFile,
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Choose File'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple dashed-border rectangle, since Flutter has no built-in one.
class DottedBorder extends StatelessWidget {
  /// Creates the dashed border container.
  const DottedBorder({super.key, required this.child});

  /// Content shown inside the border.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.card),
        color: AppColors.card,
      ),
      child: child,
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({required this.value, required this.options, required this.onChanged});

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.textField),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      items: <DropdownMenuItem<String>>[
        for (final String option in options) DropdownMenuItem<String>(value: option, child: Text(option)),
      ],
      onChanged: (String? selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}
