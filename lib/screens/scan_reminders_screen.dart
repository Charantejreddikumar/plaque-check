import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class ScanRemindersScreen extends StatefulWidget {
  const ScanRemindersScreen({super.key});

  @override
  State<ScanRemindersScreen> createState() => _ScanRemindersScreenState();
}

class _ScanRemindersScreenState extends State<ScanRemindersScreen> {
  bool _remindersEnabled = true;
  bool _morningReminder = true;
  bool _eveningReminder = false;
  bool _notifications = false;

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
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Scan Reminders',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Prepare reminder preferences for future notification support.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    children: [
                      _ReminderSwitch(
                        icon: Icons.notifications_active_outlined,
                        title: 'Enable reminders',
                        detail: 'Master reminder preference',
                        value: _remindersEnabled,
                        onChanged: (value) =>
                            setState(() => _remindersEnabled = value),
                      ),
                      const Divider(color: Colors.white24),
                      _ReminderSwitch(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Morning reminder',
                        detail: 'Placeholder for morning scan timing',
                        value: _morningReminder,
                        enabled: _remindersEnabled,
                        onChanged: (value) =>
                            setState(() => _morningReminder = value),
                      ),
                      const Divider(color: Colors.white24),
                      _ReminderSwitch(
                        icon: Icons.nights_stay_outlined,
                        title: 'Evening reminder',
                        detail: 'Placeholder for evening scan timing',
                        value: _eveningReminder,
                        enabled: _remindersEnabled,
                        onChanged: (value) =>
                            setState(() => _eveningReminder = value),
                      ),
                      const Divider(color: Colors.white24),
                      _ReminderSwitch(
                        icon: Icons.phone_iphone_outlined,
                        title: 'Notification placeholder',
                        detail:
                            'Backend/device notification setup will connect later',
                        value: _notifications,
                        enabled: _remindersEnabled,
                        onChanged: (value) =>
                            setState(() => _notifications = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderSwitch extends StatelessWidget {
  const _ReminderSwitch({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textOpacity = enabled ? 1.0 : 0.46;
    return SwitchListTile(
      value: enabled && value,
      onChanged: enabled ? onChanged : null,
      activeThumbColor: AppTheme.accent(context),
      contentPadding: EdgeInsets.zero,
      secondary: Icon(
        icon,
        color: AppTheme.accent(context).withValues(alpha: textOpacity),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimary(context).withValues(alpha: textOpacity),
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Text(
        detail,
        style: TextStyle(
          color: AppTheme.textSecondary(context).withValues(alpha: textOpacity),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
