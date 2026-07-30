import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorSettingsScreen extends StatefulWidget {
  const DoctorSettingsScreen({super.key});

  @override
  State<DoctorSettingsScreen> createState() => _DoctorSettingsScreenState();
}

class _DoctorSettingsScreenState extends State<DoctorSettingsScreen> {
  bool _emailAlerts = true;
  bool _urgentHighRiskAlerts = true;

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeProviderScope.of(context);

    return DoctorNavScaffold(
      currentRoute: '/doctor-settings',
      title: 'Doctor Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlaqueCheck Clinical Settings',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage theme preferences, patient review notifications, and clinical security controls.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Shared Theme Switcher Card (System, Light, Dark)
            GlassCard(
              borderRadius: 22,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, color: AppTheme.accent(context), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Appearance & Theme Settings',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select your preferred visual mode for PlaqueCheck Workspace',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: themeController,
                      builder: (ctx, _) {
                        return Row(
                          children: [
                            _ThemeOptionChip(
                              label: 'System Theme',
                              icon: Icons.brightness_auto,
                              isSelected: themeController.themeMode == ThemeMode.system,
                              onTap: () => themeController.setThemeMode(ThemeMode.system),
                            ),
                            const SizedBox(width: 10),
                            _ThemeOptionChip(
                              label: 'Light Mode',
                              icon: Icons.light_mode_outlined,
                              isSelected: themeController.themeMode == ThemeMode.light,
                              onTap: () => themeController.setThemeMode(ThemeMode.light),
                            ),
                            const SizedBox(width: 10),
                            _ThemeOptionChip(
                              label: 'Dark Mode',
                              icon: Icons.dark_mode_outlined,
                              isSelected: themeController.themeMode == ThemeMode.dark,
                              onTap: () => themeController.setThemeMode(ThemeMode.dark),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Notification Settings Card
            GlassCard(
              borderRadius: 22,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications_active_outlined, color: AppTheme.accent(context), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Clinical Review Notifications',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: Text(
                        'New Scan Upload Alerts',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Receive instant notifications when a patient uploads a 3-image dental scan',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      value: _emailAlerts,
                      activeColor: AppTheme.accent(context),
                      onChanged: (val) => setState(() => _emailAlerts = val),
                    ),
                    Divider(color: AppTheme.glassBorder(context)),
                    SwitchListTile(
                      title: Text(
                        'Urgent High-Risk Plaque Alerts (≥50%)',
                        style: TextStyle(
                          color: AppTheme.textPrimary(context),
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        'Push emergency notifications for severe plaque cases',
                        style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12,
                        ),
                      ),
                      value: _urgentHighRiskAlerts,
                      activeColor: AppTheme.accent(context),
                      onChanged: (val) => setState(() => _urgentHighRiskAlerts = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Security & Password Reset Tile
            GlassCard(
              borderRadius: 22,
              child: ListTile(
                leading: Icon(Icons.security_outlined, color: AppTheme.accent(context)),
                title: Text(
                  'Security & Password Management',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  'Reset doctor credentials or review active sessions',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                  ),
                ),
                trailing: Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary(context)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset link sent to your registered clinical email.')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOptionChip extends StatelessWidget {
  const _ThemeOptionChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent(context).withValues(alpha: 0.18) : AppTheme.secondarySurface(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.accent(context) : AppTheme.glassBorder(context),
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppTheme.accent(context) : AppTheme.textSecondary(context), size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
