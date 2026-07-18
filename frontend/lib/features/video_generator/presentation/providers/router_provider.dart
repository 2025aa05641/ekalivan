/// Named, type-safe route ownership through Riverpod.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../creator_portal/presentation/screens/admin_books_screen.dart';
import '../../../creator_portal/presentation/screens/admin_dashboard_screen.dart';
import '../../../creator_portal/presentation/screens/admin_pipelines_screen.dart';
import '../../../creator_portal/presentation/screens/admin_profile_screen.dart';
import '../../../creator_portal/presentation/screens/admin_videos_screen.dart';
import '../../../creator_portal/presentation/screens/login_screen.dart';
import '../../../creator_portal/presentation/screens/pipeline_complete_screen.dart';
import '../../../creator_portal/presentation/screens/pipeline_progress_screen.dart';
import '../../../creator_portal/presentation/screens/rendering_progress_screen.dart';
import '../../../creator_portal/presentation/screens/upload_book_screen.dart';
import '../../../role_select/presentation/screens/role_select_screen.dart';
import '../../../student_portal/presentation/screens/chapter_detail_screen.dart';
import '../../../student_portal/presentation/screens/chapter_list_screen.dart';
import '../../../student_portal/presentation/screens/class_selection_screen.dart';
import '../../../student_portal/presentation/screens/medium_selection_screen.dart';
import '../../../student_portal/presentation/screens/student_splash_screen.dart';
import '../../../student_portal/presentation/screens/subject_selection_screen.dart';
import '../../domain/entities/video_job_entity.dart';
import '../../../student_portal/presentation/screens/student_login_screen.dart';
import '../../../student_portal/presentation/screens/student_downloads_screen.dart';
import '../../../student_portal/presentation/screens/student_profile_screen.dart';
import '../screens/cached_video_screen.dart';
import '../screens/generation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/my_videos_screen.dart';

/// Application routes. Named routes avoid raw route strings in feature widgets.
enum AppRoute {
  /// Role-selection screen shown at app startup.
  roleSelect('/', 'roleSelect'),

  /// Top-level subject/chapter selection route (generator).
  home('/generate', 'home'),

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

  /// Creator portal book library.
  adminBooks('/admin/books', 'adminBooks'),

  /// Creator portal pipelines list (all jobs).
  adminPipelines('/admin/pipelines', 'adminPipelines'),

  /// Creator portal published videos library.
  adminVideos('/admin/videos', 'adminVideos'),

  /// Creator portal admin profile.
  adminProfile('/admin/profile', 'adminProfile'),

  /// Creator portal 8-step AI pipeline overview for one accepted job.
  adminPipeline('/admin/pipeline/:taskId', 'adminPipeline'),

  /// Creator portal Video Rendering step detail for one accepted job.
  adminRendering('/admin/pipeline/:taskId/rendering', 'adminRendering'),

  /// Creator portal pipeline-completed screen for one accepted job.
  adminComplete('/admin/pipeline/:taskId/complete', 'adminComplete'),

  /// Student portal entry screen: branding and "Get Started".
  studentSplash('/student', 'studentSplash'),

  /// Student portal medium selection (English/Tamil).
  studentMedium('/student/medium', 'student-medium'),

  /// Student portal class (grade) selection for a chosen medium.
  studentClass('/student/class/:medium', 'student-class'),

  /// Student portal subject selection for a chosen medium and grade.
  studentSubject('/student/subject/:medium/:grade', 'student-subject'),

  /// Student portal chapter list for a chosen medium, grade, and subject.
  studentChapters('/student/chapters/:medium/:grade/:subject', 'student-chapters'),

  /// Student portal chapter detail: lesson video and topics.
  studentChapterDetail('/student/chapters/:medium/:grade/:subject/:chapterId', 'student-chapter-detail'),

  /// Student portal login.
  studentLogin('/student/login', 'student-login'),

  /// Student portal downloads.
  studentDownloads('/student/downloads', 'student-downloads'),

  /// Student portal profile.
  studentProfile('/student/profile', 'student-profile');

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
    initialLocation: AppRoute.roleSelect.path,
    // Redirect any unrecognised or stale URL back to role-select screen
    // instead of throwing a GoRouter 403 / route-not-found error.
    errorBuilder: (BuildContext context, GoRouterState state) => const RoleSelectScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoute.roleSelect.path,
        name: AppRoute.roleSelect.routeName,
        builder: (BuildContext context, GoRouterState state) => const RoleSelectScreen(),
      ),
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
        path: AppRoute.adminBooks.path,
        name: AppRoute.adminBooks.routeName,
        builder: (BuildContext context, GoRouterState state) => const AdminBooksScreen(),
      ),
      GoRoute(
        path: AppRoute.adminPipelines.path,
        name: AppRoute.adminPipelines.routeName,
        builder: (BuildContext context, GoRouterState state) => const AdminPipelinesScreen(),
      ),
      GoRoute(
        path: AppRoute.adminVideos.path,
        name: AppRoute.adminVideos.routeName,
        builder: (BuildContext context, GoRouterState state) => const AdminVideosScreen(),
      ),
      GoRoute(
        path: AppRoute.adminProfile.path,
        name: AppRoute.adminProfile.routeName,
        builder: (BuildContext context, GoRouterState state) => const AdminProfileScreen(),
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
      GoRoute(
        path: AppRoute.studentSplash.path,
        name: AppRoute.studentSplash.routeName,
        builder: (BuildContext context, GoRouterState state) => const StudentSplashScreen(),
      ),
      GoRoute(
        path: AppRoute.studentMedium.path,
        name: AppRoute.studentMedium.routeName,
        builder: (BuildContext context, GoRouterState state) => const MediumSelectionScreen(),
      ),
      GoRoute(
        path: AppRoute.studentClass.path,
        name: AppRoute.studentClass.routeName,
        builder: (BuildContext context, GoRouterState state) =>
            ClassSelectionScreen(medium: state.pathParameters['medium']!),
      ),
      GoRoute(
        path: AppRoute.studentSubject.path,
        name: AppRoute.studentSubject.routeName,
        builder: (BuildContext context, GoRouterState state) => SubjectSelectionScreen(
          medium: state.pathParameters['medium']!,
          grade: state.pathParameters['grade']!,
        ),
      ),
      GoRoute(
        path: AppRoute.studentChapters.path,
        name: AppRoute.studentChapters.routeName,
        builder: (BuildContext context, GoRouterState state) => ChapterListScreen(
          medium: state.pathParameters['medium']!,
          grade: state.pathParameters['grade']!,
          subject: state.pathParameters['subject']!,
        ),
      ),
      GoRoute(
        path: AppRoute.studentChapterDetail.path,
        name: AppRoute.studentChapterDetail.routeName,
        builder: (BuildContext context, GoRouterState state) => ChapterDetailScreen(
          medium: state.pathParameters['medium']!,
          grade: state.pathParameters['grade']!,
          subject: state.pathParameters['subject']!,
          chapterId: state.pathParameters['chapterId']!,
        ),
      ),
      GoRoute(
        path: AppRoute.studentLogin.path,
        name: AppRoute.studentLogin.routeName,
        builder: (BuildContext context, GoRouterState state) => const StudentLoginScreen(),
      ),
      GoRoute(
        path: AppRoute.studentDownloads.path,
        name: AppRoute.studentDownloads.routeName,
        builder: (BuildContext context, GoRouterState state) => const StudentDownloadsScreen(),
      ),
      GoRoute(
        path: AppRoute.studentProfile.path,
        name: AppRoute.studentProfile.routeName,
        builder: (BuildContext context, GoRouterState state) => const StudentProfileScreen(),
      ),
    ],
  ),
);
