/// 16:9 video thumbnail card with a play affordance and duration badge.
library;

import 'package:flutter/material.dart';

import '../theme/app_theme_extension.dart';

/// Card showing a video's thumbnail-style preview with gradient overlay.
class VideoCard extends StatelessWidget {
  /// Creates the video card.
  const VideoCard({super.key, required this.title, required this.duration, required this.onTap});

  /// Video title.
  final String title;

  /// Formatted duration, e.g. "08:42".
  final String duration;

  /// Invoked on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final EkalivanThemeExtension tokens =
        Theme.of(context).extension<EkalivanThemeExtension>() ?? EkalivanThemeExtension.standard;
    return Semantics(
      button: true,
      label: 'Play $title, $duration',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(tokens.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Background gradient simulating plant video thumbnail
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF0D3B73)],
                    ),
                  ),
                ),
                // Texture / pattern layer
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.2,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.topLeft,
                          radius: 1.5,
                          colors: [Colors.white, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
                // Plant icon as thumbnail placeholder
                const Center(
                  child: Icon(Icons.eco_rounded, color: Colors.white30, size: 80),
                ),
                // Play button
                const Center(
                  child: Icon(Icons.play_circle_filled_rounded, color: Colors.white, size: 56),
                ),
                // Bottom overlay bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('00:45 / ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                              Text(duration, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
