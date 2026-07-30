import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorNotificationsScreen extends StatefulWidget {
  const DoctorNotificationsScreen({super.key});

  @override
  State<DoctorNotificationsScreen> createState() => _DoctorNotificationsScreenState();
}

class _DoctorNotificationsScreenState extends State<DoctorNotificationsScreen> {
  final ApiService _apiService = ApiService();

  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.fetchDoctorNotifications();
      if (!mounted) return;
      setState(() {
        _notifications = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

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
                    '${_notifications.length} Alerts',
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
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppTheme.accent(context)))
                  : _notifications.isEmpty
                      ? GlassCard(
                          borderRadius: 20,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No notifications available.',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _notifications.length,
                          itemBuilder: (ctx, i) {
                            final notif = _notifications[i] as Map<String, dynamic>;
                            final notifType = (notif['type'] ?? '').toString();
                            final isAlert = notifType == 'alert' || notifType == 'doctor_review';

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
                                    notif['title'] ?? 'Notification',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary(context),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${notif["message"] ?? ""} • ${notif["created_at"] ?? ""}',
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
