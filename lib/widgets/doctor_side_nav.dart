import 'package:flutter/material.dart';

import '../services/session_manager.dart';
import '../theme/app_theme.dart';

class DoctorNavScaffold extends StatelessWidget {
  const DoctorNavScaffold({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.floatingActionButton,
  });

  final String currentRoute;
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: AppTheme.pageDecoration(context),
          child: SafeArea(
            child: Row(
              children: [
                DoctorSideNav(currentRoute: currentRoute),
                Expanded(child: body),
              ],
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.textPrimary(context)),
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.cardColor(context),
        child: SafeArea(
          child: DoctorSideNav(currentRoute: currentRoute, isDrawerMode: true),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(child: body),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

class DoctorSideNav extends StatefulWidget {
  const DoctorSideNav({
    super.key,
    required this.currentRoute,
    this.isDrawerMode = false,
  });

  final String currentRoute;
  final bool isDrawerMode;

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
    final double width = (widget.isDrawerMode || !_isCollapsed) ? 260.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: width,
      height: double.infinity,
      margin: widget.isDrawerMode ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: widget.isDrawerMode ? BorderRadius.zero : BorderRadius.circular(24),
        border: widget.isDrawerMode ? null : Border.all(color: AppTheme.glassBorder(context)),
        boxShadow: AppTheme.isDark(context)
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
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
                    color: AppTheme.accent(context).withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.medical_services_rounded, color: AppTheme.accent(context), size: 24),
                ),
                if (widget.isDrawerMode || !_isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PlaqueCheck',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Clinical Workspace',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (!widget.isDrawerMode)
                  IconButton(
                    onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                    icon: Icon(
                      _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: AppTheme.textSecondary(context),
                    ),
                    tooltip: _isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
                  ),
              ],
            ),
          ),
          Divider(color: AppTheme.glassBorder(context), height: 1),

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
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Patients',
                  route: '/doctor-patients',
                  currentRoute: widget.currentRoute,
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  route: '/doctor-analytics',
                  currentRoute: widget.currentRoute,
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  route: '/doctor-notifications',
                  currentRoute: widget.currentRoute,
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.badge_rounded,
                  label: 'Doctor Profile',
                  route: '/doctor-profile',
                  currentRoute: widget.currentRoute,
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/doctor-settings',
                  currentRoute: widget.currentRoute,
                  isCollapsed: !widget.isDrawerMode && _isCollapsed,
                ),
              ],
            ),
          ),

          // Footer Logout Button
          Divider(color: AppTheme.glassBorder(context), height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: (!widget.isDrawerMode && _isCollapsed) ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    if (widget.isDrawerMode || !_isCollapsed) ...[
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
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
          if (!isSelected) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.accent(context).withValues(alpha: 0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppTheme.accent(context) : Colors.transparent,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? AppTheme.accent(context) : AppTheme.textSecondary(context),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
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
