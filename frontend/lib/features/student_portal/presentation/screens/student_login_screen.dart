/// Sign-in/Sign-up screen for the Student portal.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_branding.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/rounded_input.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';
import '../providers/student_auth_provider.dart';

/// The login/signup screen for students.
class StudentLoginScreen extends ConsumerStatefulWidget {
  /// Creates the student login screen.
  const StudentLoginScreen({super.key});

  @override
  ConsumerState<StudentLoginScreen> createState() => _StudentLoginScreenState();
}

class _StudentLoginScreenState extends ConsumerState<StudentLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    ref.read(isGuestProvider.notifier).state = false;
    context.pushNamed(AppRoute.studentMedium.routeName);
  }

  @override
  Widget build(BuildContext context) {
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
              // Back button to splash
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 360),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Logo
                          Center(
                            child: Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.school_rounded, color: Colors.white, size: 44),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            AppBranding.appName.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Student Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 36),
                          // Email field
                          RoundedInput(
                            label: 'Email / Username',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            darkBackground: true,
                            prefixIcon: Icons.person_outline_rounded,
                          ),
                          const SizedBox(height: 14),
                          // Password field
                          RoundedInput(
                            label: 'Password',
                            controller: _passwordController,
                            obscureText: true,
                            darkBackground: true,
                            prefixIcon: Icons.lock_outline_rounded,
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Login / Sign Up',
                            onPressed: _login,
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
