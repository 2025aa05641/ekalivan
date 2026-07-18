/// Reusable animated notification bell for AppBar actions.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// A notification model used by the bell panel.
class _Notification {
  const _Notification({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isUnread = true,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String time;
  final bool isUnread;
}

const List<_Notification> _mockNotifications = <_Notification>[
  _Notification(
    icon: Icons.check_circle_rounded,
    iconColor: AppColors.success,
    title: 'Science Std 6 — Completed',
    subtitle: '"The World of Plants" video is ready to publish.',
    time: '2 min ago',
  ),
  _Notification(
    icon: Icons.sync_rounded,
    iconColor: AppColors.warning,
    title: 'Tamil Std 8 — Processing',
    subtitle: 'Narration stage is in progress.',
    time: '15 min ago',
    isUnread: false,
  ),
  _Notification(
    icon: Icons.upload_file_rounded,
    iconColor: AppColors.primaryPurple,
    title: 'New book uploaded',
    subtitle: 'Social Science Std 6 added to the library.',
    time: '1 hr ago',
    isUnread: false,
  ),
];

/// AppBar action button that opens a notification bottom sheet.
class NotificationBell extends StatelessWidget {
  /// Creates the notification bell icon button.
  const NotificationBell({super.key});

  void _showNotifications(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => const _NotificationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.md),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
            onPressed: () => _showNotifications(context),
          ),
          // Unread badge
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.danger,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSheet extends StatelessWidget {
  const _NotificationSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      builder: (BuildContext ctx, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: <Widget>[
              // Handle bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: <Widget>[
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '1 new',
                        style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: _mockNotifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 64),
                  itemBuilder: (BuildContext ctx, int index) {
                    final _Notification n = _mockNotifications[index];
                    return Container(
                      color: n.isUnread ? AppColors.primaryBlue.withValues(alpha: 0.04) : Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: n.iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(n.icon, color: n.iconColor, size: 22),
                        ),
                        title: Text(
                          n.title,
                          style: TextStyle(
                            fontWeight: n.isUnread ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const SizedBox(height: 2),
                            Text(n.subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(n.time, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                          ],
                        ),
                        trailing: n.isUnread
                            ? Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.danger,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Mark all as read'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
