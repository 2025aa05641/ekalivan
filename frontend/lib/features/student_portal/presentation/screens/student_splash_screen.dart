/// Student portal entry screen: Ekalivan branding and a way in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../providers/student_auth_provider.dart';

/// First screen a student sees: logo, tagline, and entry into the app.
///
/// "Get Started" leads to student login; "Continue as Guest" goes directly
/// to medium selection. Both use pushNamed to preserve the back-stack so
/// pressing Back returns here. The top-left arrow returns to RoleSelectScreen.
class StudentSplashScreen extends ConsumerWidget {
  /// Creates the student splash screen.
  const StudentSplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A1E3D), Color(0xFF0D3B73), Color(0xFF0A2852)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // Back button → role select
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                    tooltip: 'Back to Role Select',
                    onPressed: () => context.goNamed(AppRoute.roleSelect.routeName),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Archer/logo illustration area
                          Center(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primaryPurple.withValues(alpha: 0.4),
                                    AppColors.primaryBlue.withValues(alpha: 0.1),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.auto_stories_rounded,
                                color: Colors.white,
                                size: 72,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          // EKALIVAN title
                          const Text(
                            'EKALIVAN',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Tamil tagline
                          const Text(
                            'தமிழில் · வேடும் · பார்ப்பேம் · படுவேம்',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 14,
                              letterSpacing: 0.5,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 52),
                          // Get Started button — pushNamed preserves back-stack
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: () => context.pushNamed(AppRoute.studentLogin.routeName),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2979FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Get Started'),
                            ),
                          ),
                          const SizedBox(height: 14),
                          // Continue as Guest button — pushNamed preserves back-stack
                          SizedBox(
                            height: 52,
                            child: OutlinedButton(
                              onPressed: () {
                                ref.read(isGuestProvider.notifier).state = true;
                                context.pushNamed(AppRoute.studentMedium.routeName);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white54, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('Continue as Guest'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
