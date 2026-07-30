import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
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
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              const DoctorSideNav(currentRoute: '/doctor-settings'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Clinical Workspace Settings', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Notification triggers, theme preferences, and clinical security controls.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                      const SizedBox(height: 24),

                      GlassCard(
                        borderRadius: 22,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Notification Preferences', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              SwitchListTile(
                                title: const Text('New Scan Upload Alerts', style: TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: const Text('Receive instant notifications when a patient uploads a 3-image dental scan', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                value: _emailAlerts,
                                activeColor: const Color(0xFF0EA5E9),
                                onChanged: (val) => setState(() => _emailAlerts = val),
                              ),
                              const Divider(color: Colors.white12),
                              SwitchListTile(
                                title: const Text('Urgent High-Risk Plaque Alerts (≥50%)', style: TextStyle(color: Colors.white, fontSize: 14)),
                                subtitle: const Text('Push emergency notifications for severe plaque cases', style: TextStyle(color: Colors.white60, fontSize: 12)),
                                value: _urgentHighRiskAlerts,
                                activeColor: const Color(0xFF0EA5E9),
                                onChanged: (val) => setState(() => _urgentHighRiskAlerts = val),
                              ),
                            ],
                          ),
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
