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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              const DoctorSideNav(currentRoute: '/doctor-notifications'),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Clinical Notifications & Alerts', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: const Color(0xFF0EA5E9).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                            child: Text('${_notifications.length} New Alerts', style: const TextStyle(color: Color(0xFF0EA5E9), fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Expanded(
                        child: ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, i) {
                            final notif = _notifications[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: GlassCard(
                                borderRadius: 18,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: notif['type'] == 'alert' ? Colors.redAccent.withValues(alpha: 0.2) : const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                                    child: Icon(
                                      notif['type'] == 'alert' ? Icons.warning_amber_rounded : Icons.notifications_active_rounded,
                                      color: notif['type'] == 'alert' ? Colors.redAccent : const Color(0xFF0EA5E9),
                                      size: 20,
                                    ),
                                  ),
                                  title: Text(notif['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  subtitle: Text('${notif["message"]} • ${notif["time"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
