/// Student portal entry screen: Ekalivan branding and a way in.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_branding.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/secondary_button.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// First screen a student sees: logo, tagline, and entry into the app.
///
/// "Get Started" and "Continue as Guest" both lead to medium selection —
/// there is no real account system yet.
class StudentSplashScreen extends StatelessWidget {
  /// Creates the student splash screen.
  const StudentSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBlue,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    AppBranding.appName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppBranding.tagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  PrimaryButton(
                    label: 'Get Started',
                    onPressed: () => context.goNamed(AppRoute.studentMedium.routeName),
                  ),
                  const SizedBox(height: 12),
                  SecondaryButton(
                    label: 'Continue as Guest',
                    onPressed: () => context.goNamed(AppRoute.studentMedium.routeName),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
