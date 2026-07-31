import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/plaque_prediction.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<SessionUser?> _user() => SessionManager.currentUser();

  Future<int> _scanCount() async {
    try {
      final backendReports = await ApiService().fetchReports();
      if (backendReports.isNotEmpty) {
        return backendReports.length;
      }
    } catch (_) {
      // Local reports keep profile counts available when the backend is offline.
    }

    final values = await SessionManager.getReportsForCurrentUser();
    return values
        .map((value) {
          try {
            return ScanReport.fromLocalJson(jsonDecode(value));
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanReport>()
        .length;
  }

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
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                const SizedBox(height: 18),
                _ProfileIdentity(userFuture: _user()),
                const SizedBox(height: 28),
                FutureBuilder<int>(
                  future: _scanCount(),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.document_scanner_outlined,
                            value: '$count',
                            label: 'Scans completed',
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _MetricCard(
                            icon: Icons.folder_open_outlined,
                            value: count == 0 ? '--' : '$count',
                            label: 'Saved reports',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                GlassCard(
                  child: Column(
                    children: [
                      _ThemeModeRow(),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.settings_outlined,
                        title: 'Settings',
                        routeName: '/settings',
                      ),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.compare_arrows_outlined,
                        title: 'Compare scans',
                        routeName: '/comparison',
                      ),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.folder_open_outlined,
                        title: 'Saved reports',
                        routeName: '/saved-reports',
                      ),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.notifications_outlined,
                        title: 'Scan reminders',
                        routeName: '/scan-reminders',
                      ),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy preferences',
                        routeName: '/privacy',
                      ),
                      const Divider(color: Colors.white24),
                      const _SettingsRow(
                        icon: Icons.help_outline,
                        title: 'Dental care support',
                        routeName: '/support',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassButton(
                  label: 'Logout',
                  icon: Icons.logout,
                  onPressed: () async {
                    await AuthService().logout();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent(context), size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({required this.userFuture});

  final Future<SessionUser?> userFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionUser?>(
      future: userFuture,
      builder: (context, snapshot) {
        final user = snapshot.data;
        final name = user?.fullName.trim().isNotEmpty == true
            ? user!.fullName
            : 'PlaqueCheck User';
        final email = user?.email.trim().isNotEmpty == true
            ? user!.email
            : 'No email saved';
        return Center(
          child: Column(
            children: [
              Container(
                width: 92,
                height: 92,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69C7C3), Color(0xFF69C7C3)],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2B7A78).withValues(alpha: 0.16),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Text(
                  user?.initials ?? 'PC',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                email,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'AI plaque detection user',
                  style: TextStyle(
                    color: AppTheme.accent(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.title, this.routeName});

  final IconData icon;
  final String title;
  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: routeName == null
          ? null
          : () => Navigator.pushNamed(context, routeName!),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2B7A78), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = ThemeProviderScope.of(context);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.contrast,
                    color: AppTheme.accent(context),
                    size: 22,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Theme mode',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _ThemeChoice(
                    label: 'System',
                    selected: controller.themeMode == ThemeMode.system,
                    onTap: () => controller.setThemeMode(ThemeMode.system),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChoice(
                    label: 'Light',
                    selected: controller.themeMode == ThemeMode.light,
                    onTap: () => controller.setThemeMode(ThemeMode.light),
                  ),
                  const SizedBox(width: 8),
                  _ThemeChoice(
                    label: 'Dark',
                    selected: controller.themeMode == ThemeMode.dark,
                    onTap: () => controller.setThemeMode(ThemeMode.dark),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.textSecondary(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
