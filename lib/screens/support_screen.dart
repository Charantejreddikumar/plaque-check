import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

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
                  'Dental Care Support',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Support resources and clinical guidance placeholders for the PlaqueCheck demo.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                const _SupportSection(
                  icon: Icons.question_answer_outlined,
                  title: 'FAQ',
                  detail:
                      'Common questions about scanning, report saving, and future AI analysis will appear here.',
                ),
                SizedBox(height: 14),
                const _SupportSection(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Help section',
                  detail:
                      'Guided dental imaging tips and troubleshooting content are ready to connect.',
                ),
                SizedBox(height: 14),
                const _SupportSection(
                  icon: Icons.mail_outline,
                  title: 'Contact placeholder',
                  detail:
                      'Support messaging and clinic handoff workflows can be connected with backend services.',
                ),
                SizedBox(height: 14),
                const _SupportSection(
                  icon: Icons.info_outline,
                  title: 'About PlaqueCheck',
                  detail:
                      'PlaqueCheck is a frontend-ready oral health tracking demo for AI plaque analysis workflows.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SupportSection extends StatelessWidget {
  const _SupportSection({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.accent(context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppTheme.accent(context), size: 22),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  detail,
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
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
