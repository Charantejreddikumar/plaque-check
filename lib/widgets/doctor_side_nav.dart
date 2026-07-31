import 'package:flutter/material.dart';

import '../services/auth_service.dart';
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
    await AuthService().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/role-selection', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final bool isExpanded = widget.isDrawerMode || !_isCollapsed;
    final double width = isExpanded ? 260.0 : 76.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.fastOutSlowIn,
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
                  color: Colors.black.withValues(alpha: 0.05),
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
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isExpanded ? 1.0 : 0.0,
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Clinical Workspace',
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (!widget.isDrawerMode)
                  IconButton(
                    onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                    icon: AnimatedRotation(
                      turns: _isCollapsed ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 240),
                      child: Icon(
                        Icons.chevron_left,
                        color: AppTheme.textSecondary(context),
                      ),
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
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.people_alt_rounded,
                  label: 'Patients Directory',
                  route: '/doctor-patients',
                  currentRoute: widget.currentRoute,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics & Insights',
                  route: '/doctor-analytics',
                  currentRoute: widget.currentRoute,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notifications',
                  route: '/doctor-notifications',
                  currentRoute: widget.currentRoute,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.badge_rounded,
                  label: 'Doctor Profile',
                  route: '/doctor-profile',
                  currentRoute: widget.currentRoute,
                  isExpanded: isExpanded,
                ),
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  route: '/doctor-settings',
                  currentRoute: widget.currentRoute,
                  isExpanded: isExpanded,
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
              hoverColor: Colors.redAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: !isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: isExpanded ? 1.0 : 0.0,
                          child: const Text(
                            'Sign Out',
                            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
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
    required this.isExpanded,
  });

  final IconData icon;
  final String label;
  final String route;
  final String currentRoute;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (Scaffold.of(context).isDrawerOpen) {
              Navigator.pop(context);
            }
            if (!isSelected) {
              Navigator.pushReplacementNamed(context, route);
            }
          },
          hoverColor: AppTheme.accent(context).withValues(alpha: 0.1),
          splashColor: AppTheme.accent(context).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accent(context).withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppTheme.accent(context) : Colors.transparent,
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisAlignment: !isExpanded ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                // Active menu left border indicator pill
                if (isSelected && isExpanded)
                  Container(
                    width: 3.5,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent(context),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? AppTheme.accent(context) : AppTheme.textSecondary(context),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: isExpanded ? 1.0 : 0.0,
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary(context) : AppTheme.textSecondary(context),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
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
