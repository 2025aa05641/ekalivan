/// Web-only video player backed by a native HTML <video> element.
///
/// Uses package:web and dart:js_interop (the modern, non-deprecated approach)
/// instead of the legacy dart:html library.
library;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

int _videoViewCounter = 0;

/// Renders a native `<video>` element via [HtmlElementView].
///
/// Use this on Chrome/web instead of [VideoPlayerView] to avoid the CORS and
/// codec restrictions that cause the video_player plugin to show errors.
class WebVideoPlayer extends StatefulWidget {
  /// Creates the web video player for [videoUrl].
  const WebVideoPlayer({super.key, required this.videoUrl});

  /// Absolute URL to the video file.
  final String videoUrl;

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    _videoViewCounter += 1;
    _viewId = 'ekalivan_video_${_videoViewCounter}_${widget.videoUrl.hashCode.abs()}';

    try {
      ui_web.platformViewRegistry.registerViewFactory(
        _viewId,
        (int viewId) {
          final web.HTMLVideoElement video =
              web.document.createElement('video') as web.HTMLVideoElement;
          video.src = widget.videoUrl;
          video.controls = true;
          video.autoplay = false;
          video.style.width = '100%';
          video.style.height = '100%';
          video.style.objectFit = 'contain';
          video.style.backgroundColor = '#000000';
          return video;
        },
      );
    } catch (_) {
      // Factory may already be registered from a prior build — safe to ignore.
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
