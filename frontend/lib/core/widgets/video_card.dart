/// 16:9 video thumbnail card with a play affordance and duration badge.
library;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme_extension.dart';

/// Card showing a video's thumbnail-style preview.
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
                const ColoredBox(color: AppColors.primaryBlue),
                const Center(child: Icon(Icons.play_circle_rounded, color: Colors.white, size: 56)),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                    child: Text(duration, style: const TextStyle(color: Colors.white, fontSize: 12)),
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
