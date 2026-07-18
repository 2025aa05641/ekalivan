/// Initial role-selection screen shown when the app starts.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../video_generator/presentation/providers/router_provider.dart';

/// Lets the user choose whether they are a Student or an Admin (Creator).
///
/// Routes:
///   Student → [AppRoute.studentSplash]
///   Admin   → [AppRoute.adminLogin]
class RoleSelectScreen extends StatelessWidget {
  /// Creates the role-selection screen.
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF050E1F), Color(0xFF0A2952), Color(0xFF0D3B73)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints viewport) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: (viewport.maxHeight - 64).clamp(0.0, double.infinity).toDouble(),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Logo
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primaryPurple.withValues(alpha: 0.5),
                              AppColors.primaryBlue.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 2),
                        ),
                        child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 56),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // App name
                    const Text(
                      'EKALIVAN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Democratizing Quality Education Through AI',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 52),
                    // Section label
                    const Text(
                      'I AM A',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0x88FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Student card
                    _RoleCard(
                      id: 'student_card',
                      icon: Icons.school_rounded,
                      title: 'Student',
                      subtitle: 'Watch AI-generated lessons,\nexplore subjects & chapters',
                      accentColor: const Color(0xFF2979FF),
                      onTap: () => context.goNamed(AppRoute.studentSplash.routeName),
                    ),
                    const SizedBox(height: 16),
                    // Admin card
                    _RoleCard(
                      id: 'admin_card',
                      icon: Icons.admin_panel_settings_rounded,
                      title: 'Admin / Creator',
                      subtitle: 'Upload books, manage pipelines\n& publish learning videos',
                      accentColor: AppColors.primaryPurple,
                      onTap: () => context.goNamed(AppRoute.adminLogin.routeName),
                    ),
                    const SizedBox(height: 40),
                    // Footer
                    Text(
                      'Built for Build in AI for India Hackathon\n❤️ Team 4NLPians',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 11,
                        height: 1.6,
                      ),
                    ),
                  ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
}
}

/// A tappable card representing one user role.
class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Semantics(
          button: true,
          label: widget.title,
          child: Container(
            key: ValueKey(widget.id),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.accentColor.withValues(alpha: 0.4), width: 1.5),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: widget.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(widget.icon, color: widget.accentColor, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.3), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
