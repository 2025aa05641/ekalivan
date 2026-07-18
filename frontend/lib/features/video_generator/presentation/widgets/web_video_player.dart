/// Conditional-import shim: loads the HTML <video> implementation on web,
/// and a no-op stub on all other platforms.
library;

export 'web_video_player_stub.dart'
    if (dart.library.ui_web) 'web_video_player_web.dart';
