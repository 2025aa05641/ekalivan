/// Plays the finished lesson video with accessible playback controls.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/widgets/accessible_error_widget.dart';

/// Renders and controls playback for a completed lesson video.
class VideoPlayerView extends StatefulWidget {
  /// Creates the video player for the video at [videoUrl].
  const VideoPlayerView({super.key, required this.videoUrl});

  /// Absolute, servable URL for the rendered video.
  final String videoUrl;

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initialization = _controller.initialize().then((_) => _controller.play());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialization,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return const AccessibleErrorWidget(message: 'This video could not be played.');
        }
        return AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: <Widget>[
              VideoPlayer(_controller),
              VideoProgressIndicator(_controller, allowScrubbing: true),
              AnimatedBuilder(
                animation: _controller,
                builder: (BuildContext context, Widget? child) {
                  return Semantics(
                    button: true,
                    label: _controller.value.isPlaying ? 'Pause' : 'Play',
                    child: GestureDetector(
                      onTap: () => _controller.value.isPlaying ? _controller.pause() : _controller.play(),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause_circle : Icons.play_circle,
                        size: 64,
                        color: Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
