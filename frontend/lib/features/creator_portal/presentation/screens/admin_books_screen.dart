/// Creator portal book library screen — shows uploaded books.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/notification_bell.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../widgets/admin_bottom_nav.dart';

/// A single book entry in the library.
class _Book {
  const _Book({
    required this.icon,
    required this.iconColor,
    required this.subject,
    required this.grade,
    required this.chapters,
    required this.medium,
    required this.lastUpdated,
  });

  final IconData icon;
  final Color iconColor;
  final String subject;
  final String grade;
  final int chapters;
  final String medium;
  final String lastUpdated;
}

const List<_Book> _books = <_Book>[
  _Book(
    icon: Icons.eco_rounded,
    iconColor: Color(0xFF2E7D32),
    subject: 'Science',
    grade: 'Std 6',
    chapters: 14,
    medium: 'English',
    lastUpdated: '2 days ago',
  ),
  _Book(
    icon: Icons.calculate_rounded,
    iconColor: Color(0xFF1565C0),
    subject: 'Mathematics',
    grade: 'Std 7',
    chapters: 12,
    medium: 'English',
    lastUpdated: '5 days ago',
  ),
  _Book(
    icon: Icons.translate_rounded,
    iconColor: Color(0xFF6A1B9A),
    subject: 'Tamil',
    grade: 'Std 8',
    chapters: 16,
    medium: 'Tamil',
    lastUpdated: '1 week ago',
  ),
  _Book(
    icon: Icons.public_rounded,
    iconColor: Color(0xFFBF360C),
    subject: 'Social Science',
    grade: 'Std 6',
    chapters: 18,
    medium: 'English',
    lastUpdated: '1 week ago',
  ),
  _Book(
    icon: Icons.science_rounded,
    iconColor: Color(0xFF00695C),
    subject: 'Science',
    grade: 'Std 7',
    chapters: 13,
    medium: 'Tamil',
    lastUpdated: '2 weeks ago',
  ),
];

/// Displays the library of uploaded books with a card per book.
class AdminBooksScreen extends StatelessWidget {
  /// Creates the admin books screen.
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(
        title: const Text('Book Library'),
        automaticallyImplyLeading: false,
        actions: const <Widget>[NotificationBell()],
      ),
      bottomNavigationBar: const AdminBottomNav(current: AdminNavDestination.books),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.goNamed(AppRoute.adminUpload.routeName),
        backgroundColor: AppColors.primaryPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text('Upload Book', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 100),
        children: <Widget>[
          // Stats header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryBlue, AppColors.secondaryBlue],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.menu_book_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${_books.length} Books',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                    const Text(
                      'in the library',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '2 mediums',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('All Books', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          for (final _Book book in _books) ...<Widget>[
            _BookCard(book: book),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard({required this.book});

  final _Book book;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: () {
          // Show a sheet with book details
          showModalBottomSheet<void>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (_) => _BookDetailSheet(book: book),
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: book.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(book.icon, color: book.iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${book.subject} — ${book.grade}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: <Widget>[
                        _TagChip(label: book.medium, color: AppColors.primaryBlue),
                        const SizedBox(width: 6),
                        _TagChip(label: '${book.chapters} chapters', color: AppColors.primaryPurple),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Updated ${book.lastUpdated}',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _BookDetailSheet extends StatelessWidget {
  const _BookDetailSheet({required this.book});

  final _Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: book.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(book.icon, color: book.iconColor, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${book.subject} — ${book.grade}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                  ),
                  Text(book.medium, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailItem(label: 'Chapters', value: book.chapters.toString()),
          _DetailItem(label: 'Medium', value: book.medium),
          _DetailItem(label: 'Last Updated', value: book.lastUpdated),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                context.goNamed(AppRoute.adminPipelines.routeName);
              },
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('View Pipelines'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  const _DetailItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
