import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final List<Map<String, String>> _notifications = [
    {
      'title': 'New Scan Uploaded',
      'message': 'Patient User #12 uploaded a 3-image dental scan requiring review.',
      'time': '10 mins ago',
      'type': 'scan',
    },
    {
      'title': 'High Risk Plaque Alert',
      'message': 'Patient User #8 detected with 68% severe plaque score.',
      'time': '1 hour ago',
      'type': 'alert',
    },
    {
      'title': 'Patient Follow-up Reminder',
      'message': 'Scheduled follow-up hygiene visit for Patient #4 is due today.',
      'time': '3 hours ago',
      'type': 'reminder',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return DoctorNavScaffold(
      currentRoute: '/doctor-notifications',
      title: 'Clinical Notifications',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Clinical Notifications & Alerts',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent(context).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_notifications.length} New Alerts',
                    style: TextStyle(
                      color: AppTheme.accent(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Expanded(
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (ctx, i) {
                  final notif = _notifications[i];
                  final isAlert = notif['type'] == 'alert';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      borderRadius: 18,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAlert ? Colors.redAccent.withValues(alpha: 0.2) : AppTheme.accent(context).withValues(alpha: 0.2),
                          child: Icon(
                            isAlert ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
                            color: isAlert ? Colors.redAccent : AppTheme.accent(context),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          notif['title']!,
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Text(
                          '${notif["message"]} • ${notif["time"]}',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
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
