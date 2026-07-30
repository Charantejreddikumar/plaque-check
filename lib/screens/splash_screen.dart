import 'dart:math' as math;
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
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _rotateController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final user = await SessionManager.currentUser();
      if (!mounted) return;
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/role-selection');
      } else if (user.role == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else if (user.role == 'administrator') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _rotateController.dispose();
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
              animation: _entranceController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 0.95 + (_entranceController.value * 0.08),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF38BDF8).withAlpha(40),
                          blurRadius: 90,
                          spreadRadius: 8,
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
                        SizedBox(
                          width: 124,
                          height: 124,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Revolving glowing orbit ring around the logo
                              RotationTransition(
                                turns: _rotateController,
                                child: CustomPaint(
                                  size: const Size(124, 124),
                                  painter: _OrbitRingPainter(),
                                ),
                              ),
                              // Central high-resolution logo badge
                              Container(
                                width: 88,
                                height: 88,
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0EA5E9).withAlpha(60),
                                      blurRadius: 24,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/app_logo.png',
                                    width: 72,
                                    height: 72,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ],
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

class _OrbitRingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final sweepGradient = SweepGradient(
      colors: const [
        Color(0x0038BDF8),
        Color(0xFF38BDF8),
        Color(0xFF2B7A78),
        Color(0x0038BDF8),
      ],
      stops: const [0.0, 0.45, 0.85, 1.0],
    );

    final arcPaint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, arcPaint);

    final p1 = Offset(
      center.dx + radius * math.cos(math.pi * 0.45),
      center.dy + radius * math.sin(math.pi * 0.45),
    );
    final glowPaint1 = Paint()
      ..color = const Color(0xFF38BDF8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(p1, 5, glowPaint1);
    canvas.drawCircle(p1, 3.5, Paint()..color = Colors.white);

    final p2 = Offset(
      center.dx + radius * math.cos(math.pi * 1.45),
      center.dy + radius * math.sin(math.pi * 1.45),
    );
    canvas.drawCircle(p2, 4, glowPaint1);
    canvas.drawCircle(p2, 2.5, Paint()..color = const Color(0xFF38BDF8));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
