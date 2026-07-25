import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
                  'Settings',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage PlaqueCheck preferences and placeholders for future backend services.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                const _BackendStatusCard(),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    children: const [
                      _ThemeSelector(),
                      Divider(color: Colors.white24),
                      _SettingsTile(
                        icon: Icons.developer_mode_outlined,
                        title: 'Developer Settings',
                        detail: 'Backend IP and port',
                        routeName: '/developer-settings',
                      ),
                      Divider(color: Colors.white24),
                      _SettingsTile(
                        icon: Icons.notifications_outlined,
                        title: 'Notifications',
                        detail: 'Reminder preferences placeholder',
                        routeName: '/scan-reminders',
                      ),
                      Divider(color: Colors.white24),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy',
                        detail: 'Consent and data controls placeholder',
                        routeName: '/privacy',
                      ),
                      Divider(color: Colors.white24),
                      _SettingsTile(
                        icon: Icons.language_outlined,
                        title: 'Language',
                        detail: 'English',
                        message:
                            'Language selection will be available when localization is connected.',
                      ),
                      Divider(color: Colors.white24),
                      _SettingsTile(
                        icon: Icons.info_outline,
                        title: 'About',
                        detail: 'PlaqueCheck frontend demo',
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
                    await SessionManager.clearSession();
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

class _BackendStatusCard extends StatelessWidget {
  const _BackendStatusCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: ApiService().isBackendHealthy(),
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        final waiting = snapshot.connectionState == ConnectionState.waiting;
        final color = connected
            ? const Color(0xFF34D399)
            : const Color(0xFFFBBF24);

        return GlassCard(
          borderRadius: 26,
          opacity: 0.14,
          borderOpacity: 0.22,
          glowColor: connected
              ? const Color(0xFF34D399)
              : const Color(0xFF2B7A78),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Icon(
                  waiting
                      ? Icons.sync
                      : connected
                      ? Icons.cloud_done_outlined
                      : Icons.cloud_off_outlined,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waiting
                          ? 'Checking Backend'
                          : connected
                          ? 'Backend Connected'
                          : 'Offline Mode',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      connected
                          ? 'FastAPI diagnostics are available.'
                          : 'Local history remains available.',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

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
              const _SettingsTile(
                icon: Icons.contrast_outlined,
                title: 'Theme',
                detail: 'Choose how PlaqueCheck appears',
                showChevron: false,
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
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

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.detail,
    this.showChevron = true,
    this.routeName,
    this.message,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool showChevron;
  final String? routeName;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: !showChevron
          ? null
          : () {
              if (routeName != null) {
                Navigator.pushNamed(context, routeName!);
                return;
              }
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(title),
                  content: Text(
                    message ??
                        'This preference is ready for backend connection.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.accent(context), size: 22),
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
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: AppTheme.textSecondary(context)),
          ],
        ),
      ),
    );
  }
}
