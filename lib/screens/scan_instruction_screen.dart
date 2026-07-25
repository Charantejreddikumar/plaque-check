import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class ScanInstructionScreen extends StatelessWidget {
  const ScanInstructionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Scan Instructions',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prepare a clear dental image for AI-assisted plaque review.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 26),
                const _ScannerIllustration(),
                const SizedBox(height: 22),
                _InstructionTile(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Use good lighting',
                  detail:
                      'Avoid shadows and glare so tooth surfaces are visible.',
                ),
                const SizedBox(height: 14),
                _InstructionTile(
                  icon: Icons.center_focus_strong_outlined,
                  title: 'Hold steady',
                  detail: 'Keep the camera centered and capture a sharp image.',
                ),
                const SizedBox(height: 14),
                _InstructionTile(
                  icon: Icons.sentiment_satisfied_alt_outlined,
                  title: 'Show teeth clearly',
                  detail:
                      'Frame the mouth so visible plaque regions can be reviewed.',
                ),
                const SizedBox(height: 14),
                _InstructionTile(
                  icon: Icons.science_outlined,
                  title: 'UV guidance placeholder',
                  detail: 'Future clinical imaging guidance can connect here.',
                ),
                const SizedBox(height: 28),
                GlassButton(
                  label: 'Continue to Scan',
                  icon: Icons.arrow_forward_rounded,
                  isPrimary: true,
                  onPressed: () => Navigator.pushNamed(context, '/scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScannerIllustration extends StatelessWidget {
  const _ScannerIllustration();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 34,
      opacity: 0.18,
      borderOpacity: 0.24,
      glowColor: const Color(0xFF69C7C3),
      child: SizedBox(
        height: 190,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 138,
              height: 138,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF69C7C3).withValues(alpha: 0.34),
                    const Color(0xFF69C7C3).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.32),
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: Colors.white.withValues(alpha: 0.42)),
              ),
              child: const Icon(
                Icons.document_scanner_outlined,
                color: Color(0xFF2B7A78),
                size: 58,
              ),
            ),
            Positioned(
              left: 30,
              right: 30,
              bottom: 32,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0x000EA5E9),
                      Color(0xFF2B7A78),
                      Color(0x000EA5E9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InstructionTile extends StatelessWidget {
  const _InstructionTile({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.accent(context), size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
