import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class DoctorSideNav extends StatefulWidget {
  const DoctorSideNav({
    super.key,
    required this.currentRoute,
  });

  final String currentRoute;

  @override
  State<DoctorSideNav> createState() => _DoctorSideNavState();
}

class _DoctorSideNavState extends State<DoctorSideNav> {
  bool _isCollapsed = false;

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final double width = _isCollapsed ? 76.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header / Branding
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0EA5E9).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0EA5E9), size: 24),
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PlaqueCheck',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                        Text(
                          'Clinical Dental Suite',
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
                IconButton(
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  icon: Icon(_isCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white70),
                  tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/doctor-dashboard',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Patients',
                  route: '/doctor-patients',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.rate_review_rounded,
                  label: 'Report Reviews',
                  route: '/doctor-dashboard',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  route: '/doctor-analytics',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  route: '/doctor-notifications',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.badge_rounded,
                  label: 'Doctor Profile',
                  route: '/doctor-profile',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/doctor-settings',
                  currentRoute: widget.currentRoute,
                  isCollapsed: _isCollapsed,
                ),
              ],
            ),
          ),

          // Footer Logout Button
          const Divider(color: Colors.white12, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: _isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    if (!_isCollapsed) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.currentRoute,
    required this.isCollapsed,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isCollapsed;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0EA5E9).withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF0EA5E9) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? const Color(0xFF0EA5E9) : Colors.white60,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
