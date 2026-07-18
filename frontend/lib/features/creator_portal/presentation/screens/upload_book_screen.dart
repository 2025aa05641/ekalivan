/// Creator portal screen for selecting a textbook PDF and its target class.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_selector/file_selector.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../video_generator/domain/entities/video_job_entity.dart';
import '../../../video_generator/domain/value_objects/video_generation_request_params.dart';
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
  XFile? _selectedFile;
  int _selectedFileSize = 0;
  String _medium = 'English';
  String _grade = 'Grade 6';
  String _subject = 'Science';
  final TextEditingController _chapterTitleController = TextEditingController(
    text: 'Chapter 1',
  );
  bool _isSubmitting = false;

  @override
  void dispose() {
    _chapterTitleController.dispose();
    super.dispose();
  }

  /// Extracts the numeric grade from the display string (e.g. "Grade 6" → "6").
  String get _gradeNumber => _grade.replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _uploadAndProcess() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF file first.')));
      return;
    }
    final String chapterTitle = _chapterTitleController.text.trim();
    if (chapterTitle.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a chapter title.')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    
    try {
      // 1. Upload file to backend
      final bytes = await _selectedFile!.readAsBytes();
      final String fileStoragePath = await ref.read(videoRepositoryProvider).uploadVideoSource(
        bytes: bytes,
        filename: _selectedFile!.name,
      );

      // 2. Request Generation
      final VideoGenerationRequestParams params = VideoGenerationRequestParams(
        classLevel: _gradeNumber,
        subject: _subject,
        chapterTitle: chapterTitle,
        fileStoragePath: fileStoragePath,
      );

    await ref.read(videoGenerationProvider.notifier).request(params);
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
    
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        // Use pop() so this works whether reached via pushNamed or goNamed.
        leading: BackButton(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(AppRoute.adminDashboard.routeName);
            }
          },
        ),
        title: const Text('Upload New Book'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.home_rounded),
            tooltip: 'Admin Home',
            onPressed: () => context.goNamed(AppRoute.adminDashboard.routeName),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          // Drop zone
          _DottedDropZone(
            hasFile: _selectedFile != null,
            onChooseFile: () async {
              const XTypeGroup typeGroup = XTypeGroup(
                label: 'PDFs',
                extensions: <String>['pdf'],
              );
              final XFile? file = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
              if (file != null) {
                final int size = await file.length();
                setState(() {
                  _selectedFile = file;
                  _selectedFileSize = size;
                });
              }
            },
          ),
          // Selected file row
          if (_selectedFile != null) ...<Widget>[
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
                          _selectedFile!.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Text(
                          _selectedFileSize < 1024 * 1024 
                              ? '${(_selectedFileSize / 1024).toStringAsFixed(1)} KB'
                              : '${(_selectedFileSize / (1024 * 1024)).toStringAsFixed(1)} MB',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _selectedFile = null),
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
          _Dropdown(
            value: _medium,
            options: const <String>['English', 'Tamil'],
            onChanged: (String v) => setState(() => _medium = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Select Class', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _Dropdown(
            value: _grade,
            options: const <String>[
              'Grade 1', 'Grade 2', 'Grade 3', 'Grade 4', 'Grade 5',
              'Grade 6', 'Grade 7', 'Grade 8', 'Grade 9', 'Grade 10',
              'Grade 11', 'Grade 12',
            ],
            onChanged: (String v) => setState(() => _grade = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Select Subject', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          _Dropdown(
            value: _subject,
            options: const <String>[
              'Science', 'Mathematics', 'English', 'Tamil', 'Social Science',
            ],
            onChanged: (String v) => setState(() => _subject = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Chapter Title', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          TextFormField(
            controller: _chapterTitleController,
            decoration: InputDecoration(
              hintText: 'e.g. The World of Plants',
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
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Upload & Process',
            loading: _isSubmitting,
            onPressed: _selectedFile == null || _isSubmitting ? null : _uploadAndProcess,
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
