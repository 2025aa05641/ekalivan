/// Placeholder screen for downloaded videos.
library;

import 'package:flutter/material.dart';

import '../../../../core/widgets/app_scaffold.dart';
import '../widgets/student_bottom_nav.dart';

/// Shows an empty state for the downloads section.
class StudentDownloadsScreen extends StatelessWidget {
  /// Creates the downloads screen.
  const StudentDownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppBar(title: const Text('Downloads')),
      bottomNavigationBar: const StudentBottomNav(current: StudentNavDestination.downloads),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.download_done_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text(
                'No Downloads Yet',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Videos you download for offline viewing will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
