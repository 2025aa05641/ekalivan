/// Stub implementation of WebVideoPlayer for non-web platforms.
library;

import 'package:flutter/material.dart';

/// On non-web platforms, show a simple placeholder instead of the
/// platform-view-based HTML video element.
class WebVideoPlayer extends StatelessWidget {
  /// Creates the non-web stub player.
  const WebVideoPlayer({super.key, required this.videoUrl});

  /// Video URL (unused on non-web).
  final String videoUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Text(
          'Video player\nnot available on this platform.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 13),
        ),
      ),
    );
  }
}
