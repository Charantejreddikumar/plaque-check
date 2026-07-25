import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final user = await SessionManager.currentUser();
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        user == null ? '/login' : '/dashboard',
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (_controller.value * 0.08),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF38BDF8,
                          ).withValues(alpha: 0.16),
                          blurRadius: 80,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: GlassCard(
                    borderRadius: 34,
                    opacity: 0.14,
                    borderOpacity: 0.24,
                    glowColor: const Color(0xFF2B7A78),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2B7A78), Color(0xFF3BA7A4)],
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF0EA5E9,
                                ).withValues(alpha: 0.2),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.health_and_safety,
                            color: Colors.white,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'PlaqueCheck',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Know Your Plaque. Own Your Health.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
