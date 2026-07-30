import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // App Branding Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.accent(context).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.biotech, color: AppTheme.accent(context), size: 48),
                ),
                const SizedBox(height: 16),
                Text(
                  'PlaqueCheck',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Clinical AI Dental Network',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 36),

                // Instruction Banner
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select Your Portal Role',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose your workspace to proceed to secure login.',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Patient Selection Card
                _RoleSelectionCard(
                  title: 'Patient Workspace',
                  subtitle: 'Scan your teeth, track plaque AI scores, and view doctor recommendations.',
                  icon: Icons.person_rounded,
                  badge: '🧑 Patient',
                  color: AppTheme.isDark(context) ? const Color(0xFF3AAFA9) : const Color(0xFF2B7A78),
                  onTap: () => Navigator.pushNamed(context, '/patient-login'),
                ),
                const SizedBox(height: 16),

                // 2. Doctor Selection Card
                _RoleSelectionCard(
                  title: 'Doctor Portal',
                  subtitle: 'Review 3-image patient scans, override AI scores, write notes & prescribe treatment.',
                  icon: Icons.medical_services_rounded,
                  badge: '🩺 Doctor',
                  color: AppTheme.isDark(context) ? const Color(0xFF63B3ED) : const Color(0xFF2B6CB0),
                  onTap: () => Navigator.pushNamed(context, '/doctor-login'),
                ),
                const SizedBox(height: 16),

                // 3. Administrator Selection Card
                _RoleSelectionCard(
                  title: 'Administrator Portal',
                  subtitle: 'Approve doctor account applications, manage users, and inspect security audit logs.',
                  icon: Icons.admin_panel_settings_rounded,
                  badge: '🛡️ Administrator',
                  color: AppTheme.isDark(context) ? const Color(0xFFB794F4) : const Color(0xFF6B46C1),
                  onTap: () => Navigator.pushNamed(context, '/admin-login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  const _RoleSelectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        borderRadius: 24,
        opacity: 0.16,
        borderOpacity: 0.25,
        glowColor: color,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          badge,
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textSecondary(context),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
