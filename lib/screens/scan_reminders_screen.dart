import 'package:flutter/material.dart';
import '../services/reminder_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';

class ScanRemindersScreen extends StatefulWidget {
  const ScanRemindersScreen({super.key});

  @override
  State<ScanRemindersScreen> createState() => _ScanRemindersScreenState();
}

class _ScanRemindersScreenState extends State<ScanRemindersScreen> {
  final ReminderService _reminderService = ReminderService();

  bool _isLoading = true;
  bool _remindersEnabled = false;
  String _frequency = 'daily'; // 'daily', 'every_2_days', 'weekly', 'custom'
  int _customDays = 3;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _reminderService.loadSettings();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = settings.enabled;
      _frequency = settings.frequency;
      _customDays = settings.customDays;
      _reminderTime = settings.timeOfDay;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final settings = ReminderSettings(
      enabled: _remindersEnabled,
      frequency: _frequency,
      customDays: _customDays,
      hour: _reminderTime.hour,
      minute: _reminderTime.minute,
    );

    if (_remindersEnabled) {
      await _reminderService.requestPermissions();
    }

    await _reminderService.saveAndRescheduleSettings(settings);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _remindersEnabled
              ? 'Scan reminders saved and scheduled successfully!'
              : 'Scan reminders disabled and cancelled.',
        ),
        backgroundColor: const Color(0xFF2B7A78),
      ),
    );
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
              backgroundColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _reminderTime) {
      setState(() => _reminderTime = picked);
      await _saveSettings();
    }
  }

  Future<void> _selectCustomDays() async {
    final controller = TextEditingController(text: _customDays.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Custom Interval (Days)'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Number of days between scans',
            hintText: 'e.g. 3',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0 && val <= 30) {
                Navigator.pop(context, val);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result != _customDays) {
      setState(() => _customDays = result);
      await _saveSettings();
    }
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
                  'Set regular reminder notifications to maintain consistent oral hygiene checks.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3AAFA9)),
                    ),
                  )
                else ...[
                  GlassCard(
                    child: Column(
                      children: [
                        _ReminderSwitch(
                          icon: Icons.notifications_active_outlined,
                          title: 'Enable Scan Reminders',
                          detail: _remindersEnabled
                              ? 'Reminders are active'
                              : 'Turn on to schedule local notifications',
                          value: _remindersEnabled,
                          onChanged: (value) async {
                            setState(() => _remindersEnabled = value);
                            await _saveSettings();
                          },
                        ),
                        if (_remindersEnabled) ...[
                          const Divider(color: Colors.white24),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.access_time_outlined,
                              color: AppTheme.accent(context),
                            ),
                            title: Text(
                              'Reminder Time',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              _reminderTime.format(context),
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _selectTime,
                              child: const Text('Change'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  if (_remindersEnabled) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Reminder Frequency',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        children: [
                          RadioListTile<String>(
                            value: 'daily',
                            groupValue: _frequency,
                            title: const Text('Daily'),
                            subtitle: const Text('Receive a reminder every day'),
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _frequency = val);
                                await _saveSettings();
                              }
                            },
                          ),
                          const Divider(color: Colors.white24),
                          RadioListTile<String>(
                            value: 'every_2_days',
                            groupValue: _frequency,
                            title: const Text('Every 2 Days'),
                            subtitle: const Text('Receive a reminder every alternate day'),
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _frequency = val);
                                await _saveSettings();
                              }
                            },
                          ),
                          const Divider(color: Colors.white24),
                          RadioListTile<String>(
                            value: 'weekly',
                            groupValue: _frequency,
                            title: const Text('Weekly'),
                            subtitle: const Text('Receive a reminder once every week'),
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _frequency = val);
                                await _saveSettings();
                              }
                            },
                          ),
                          const Divider(color: Colors.white24),
                          RadioListTile<String>(
                            value: 'custom',
                            groupValue: _frequency,
                            title: Text('Custom Interval ($_customDays Days)'),
                            subtitle: const Text('Specify custom interval in days'),
                            onChanged: (val) async {
                              if (val != null) {
                                setState(() => _frequency = val);
                                await _saveSettings();
                              }
                            },
                            secondary: _frequency == 'custom'
                                ? IconButton(
                                    icon: const Icon(Icons.edit_calendar, size: 20),
                                    onPressed: _selectCustomDays,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  GlassButton(
                    label: _remindersEnabled ? 'Save Preference' : 'Turn On Reminders',
                    icon: Icons.check_circle_outline,
                    isPrimary: true,
                    onPressed: () async {
                      if (!_remindersEnabled) {
                        setState(() => _remindersEnabled = true);
                      }
                      await _saveSettings();
                    },
                  ),
                ],
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
