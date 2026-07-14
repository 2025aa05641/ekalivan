/// Named, type-safe route ownership through Riverpod.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../creator_portal/presentation/screens/admin_dashboard_screen.dart';
import '../../../creator_portal/presentation/screens/login_screen.dart';
import '../../../creator_portal/presentation/screens/pipeline_complete_screen.dart';
import '../../../creator_portal/presentation/screens/pipeline_progress_screen.dart';
import '../../../creator_portal/presentation/screens/rendering_progress_screen.dart';
import '../../../creator_portal/presentation/screens/upload_book_screen.dart';
import '../../domain/entities/video_job_entity.dart';
import '../screens/cached_video_screen.dart';
import '../screens/generation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_videos_screen.dart';

/// Application routes. Named routes avoid raw route strings in feature widgets.
enum AppRoute {
  /// Top-level subject selection route.
  home('/', 'home'),

  /// Generation progress and playback route for one accepted job.
  generation('/videos/:taskId', 'generation'),

  /// List of previously generated videos cached for offline playback.
  myVideos('/my-videos', 'myVideos'),

  /// Playback route for one cached video, given via `extra`.
  cachedVideo('/my-videos/player', 'cachedVideo'),

  /// Creator portal sign-in.
  adminLogin('/admin/login', 'adminLogin'),

  /// Creator portal home: metrics and recent activity.
  adminDashboard('/admin/dashboard', 'adminDashboard'),

  /// Creator portal book upload.
  adminUpload('/admin/upload', 'adminUpload'),

  /// Creator portal 8-step AI pipeline overview for one accepted job.
  adminPipeline('/admin/pipeline/:taskId', 'adminPipeline'),

  /// Creator portal Video Rendering step detail for one accepted job.
  adminRendering('/admin/pipeline/:taskId/rendering', 'adminRendering'),

  /// Creator portal pipeline-completed screen for one accepted job.
  adminComplete('/admin/pipeline/:taskId/complete', 'adminComplete');

  /// Creates a named application route.
  const AppRoute(this.path, this.routeName);

  /// URL path.
  final String path;

  /// GoRouter route name.
  final String routeName;
}

/// Provides the immutable router configuration.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (Ref ref) => GoRouter(
    initialLocation: AppRoute.home.path,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.home.path,
        name: AppRoute.home.routeName,
        builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoute.generation.path,
        name: AppRoute.generation.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            GenerationScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: AppRoute.myVideos.path,
        name: AppRoute.myVideos.routeName,
        builder: (BuildContext context, GoRouterState state) => const MyVideosScreen(),
      ),
      GoRoute(
        path: AppRoute.cachedVideo.path,
        name: AppRoute.cachedVideo.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            CachedVideoScreen(job: state.extra! as VideoJobEntity),
      ),
      GoRoute(
        path: AppRoute.adminLogin.path,
        name: AppRoute.adminLogin.routeName,
        builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoute.adminDashboard.path,
        name: AppRoute.adminDashboard.routeName,
        builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoute.adminUpload.path,
        name: AppRoute.adminUpload.routeName,
        builder: (BuildContext context, GoRouterState state) => const UploadBookScreen(),
      ),
      GoRoute(
        path: AppRoute.adminPipeline.path,
        name: AppRoute.adminPipeline.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            PipelineProgressScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: AppRoute.adminRendering.path,
        name: AppRoute.adminRendering.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            RenderingProgressScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(
        path: AppRoute.adminComplete.path,
        name: AppRoute.adminComplete.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            PipelineCompleteScreen(taskId: state.pathParameters['taskId']!),
      ),
    ],
  ),
);
