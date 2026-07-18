/// Creator portal screen for selecting a textbook PDF and its target class.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/demo_chapter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../../../video_generator/presentation/providers/video_generation_provider.dart';

/// Upload-a-book screen: choose a PDF, then its medium and class.
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
          // Drop zone
          _DottedDropZone(
            hasFile: _selectedFileName != null,
            onChooseFile: () => setState(() => _selectedFileName = 'Science_6th_Standard.pdf'),
          ),
          // Selected file row
          if (_selectedFileName != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.danger, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _selectedFileName!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const Text('12.4 MB', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedFileName = null),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
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
class _DottedDropZone extends StatelessWidget {
  const _DottedDropZone({super.key, required this.hasFile, required this.onChooseFile});

  final bool hasFile;
  final VoidCallback onChooseFile;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryBlue.withValues(alpha: 0.4), width: 1.5, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(16),
        color: AppColors.primaryBlue.withValues(alpha: 0.04),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryPurple.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_upload_outlined,
                size: 32,
                color: AppColors.primaryPurple.withValues(alpha: hasFile ? 0.4 : 1),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Drag & drop your PDF here',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: hasFile ? Colors.grey : const Color(0xFF0F172A),
              ),
            ),
            const Text('or', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 10),
            SizedBox(
              width: 140,
              height: 42,
              child: ElevatedButton.icon(
                onPressed: onChooseFile,
                icon: const Icon(Icons.upload_file_rounded, size: 18),
                label: const Text('Choose File'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// DottedDropZone kept as public alias for backward compatibility.
class DottedDropZone extends _DottedDropZone {
  /// Creates the drop zone.
  const DottedDropZone({super.key, required super.hasFile, required super.onChooseFile});
}

/// Simple dashed-border rectangle placeholder (now unused, kept for compatibility).
class DottedBorder extends StatelessWidget {
  /// Creates the dashed border container.
  const DottedBorder({super.key, required this.child});

  /// Content shown inside the border.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(12),
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
      value: value,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
