import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  SessionUser? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await SessionManager.currentUser();
    if (!mounted) return;
    setState(() => _user = user);
  }

  @override
  Widget build(BuildContext context) {
    return DoctorNavScaffold(
      currentRoute: '/doctor-profile',
      title: 'Doctor Clinical Credentials',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Doctor Professional Credentials & Profile',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your medical qualifications, clinic information, and clinical schedule.',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 24),

            // Profile Header Card
            GlassCard(
              borderRadius: 24,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.accent(context).withValues(alpha: 0.25),
                      child: Icon(Icons.person_rounded, color: AppTheme.accent(context), size: 44),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${_user?.fullName ?? "Dentist"}',
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'MDS Periodontics & Oral Implantology',
                            style: TextStyle(
                              color: AppTheme.accent(context),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_user?.email ?? ""} • Reg. No: DENT-99182-AZ',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Professional Information Card
            GlassCard(
              borderRadius: 22,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinic & Hospital Credentials',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileItem(icon: Icons.storefront_rounded, label: 'Primary Clinic', value: 'PlaqueCheck Dental Clinic & AI Center'),
                    _ProfileItem(icon: Icons.local_hospital_rounded, label: 'Affiliated Hospital', value: 'City General Medical Center'),
                    _ProfileItem(icon: Icons.access_time_rounded, label: 'Clinical Working Hours', value: 'Mon - Sat (09:00 AM - 06:00 PM)'),
                    _ProfileItem(icon: Icons.phone_outlined, label: 'Emergency Contact', value: '+1 (555) 019-2831'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.accent(context), size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 11),
              ),
              Text(
                value,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
