import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import '../widgets/glass_card.dart';

enum AdminSection {
  dashboard,
  patients,
  doctors,
  reports,
  aiMonitoring,
  analytics,
  notifications,
  systemHealth,
  auditLogs,
  storage,
  settings,
  profile,
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _globalSearchController = TextEditingController();

  AdminSection _currentSection = AdminSection.dashboard;
  bool _isSidebarCollapsed = false;
  bool _isLoading = true;

  // Data states
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _patients = [];
  List<dynamic> _doctors = [];
  List<dynamic> _reports = [];
  Map<String, dynamic>? _aiStatus;
  Map<String, dynamic>? _analyticsData;
  List<dynamic> _notifications = [];
  Map<String, dynamic>? _systemHealth;
  List<dynamic> _auditLogs = [];
  Map<String, dynamic>? _storageStats;
  Map<String, dynamic>? _adminProfile;

  // Filter & Search states
  String _patientSearchQuery = '';
  String _patientFilter = 'all';
  final String _doctorSearchQuery = '';
  final String _reportFilter = 'all';
  final String _reportSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllAdminData();
  }

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllAdminData() async {
    setState(() => _isLoading = true);
    try {
      final dash = await _apiService.fetchAdminDashboard();
      final pts = await _apiService.fetchAdminPatients(query: _patientSearchQuery, filterType: _patientFilter);
      final docs = await _apiService.fetchDoctorsList();
      final rpts = await _apiService.fetchAdminReports(filterType: _reportFilter, query: _reportSearchQuery);
      final ai = await _apiService.fetchAiMonitoringStatus();
      final aly = await _apiService.fetchAdminAnalyticsData();
      final notifs = await _apiService.fetchAdminNotifications();
      final sys = await _apiService.fetchSystemHealth();
      final logs = await _apiService.fetchAuditLogs();
      final stg = await _apiService.fetchStorageStats();
      final prof = await _apiService.fetchAdminProfile();

      if (!mounted) return;
      setState(() {
        _dashboardData = dash;
        _patients = pts;
        _doctors = docs;
        _reports = rpts;
        _aiStatus = ai;
        _analyticsData = aly;
        _notifications = notifs;
        _systemHealth = sys;
        _auditLogs = logs;
        _storageStats = stg;
        _adminProfile = prof;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _triggerExport(String resource) async {
    try {
      await _apiService.exportAdminData(resource);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF2B7A78),
          content: Text('Successfully exported $resource data to CSV!'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent()) : null,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: Row(
            children: [
              if (isDesktop) _buildSidebarContent(),
              Expanded(
                child: Column(
                  children: [
                    _buildGlobalHeader(isDesktop),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF805AD5)))
                          : RefreshIndicator(
                              onRefresh: _loadAllAdminData,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: _buildActiveSectionView(),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Header Bar with Global Search, Notifications & Theme Switcher
  Widget _buildGlobalHeader(bool isDesktop) {
    final themeProvider = ThemeProviderScope.of(context);
    final unreadCount = _dashboardData?['unread_notifications'] ?? 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? const Color(0xFF0F172A).withValues(alpha: 0.7)
            : Colors.white.withValues(alpha: 0.8),
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            Builder(
              builder: (ctx) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF805AD5)),
                onPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: TextField(
                controller: _globalSearchController,
                style: TextStyle(color: AppTheme.textPrimary(context), fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Global Search Patients, Doctors, Reports, Audit Logs...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary(context).withValues(alpha: 0.6), fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF805AD5), size: 18),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (query) {
                  if (query.trim().isNotEmpty) {
                    _performGlobalSearch(query.trim());
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Toggle Dark / Light Theme',
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: const Color(0xFF805AD5),
            ),
            onPressed: () {
              themeProvider.setThemeMode(themeProvider.themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          Stack(
            children: [
              IconButton(
                tooltip: 'System Notifications',
                icon: const Icon(Icons.notifications_outlined, color: Colors.white70),
                onPressed: () {
                  setState(() => _currentSection = AdminSection.notifications);
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => setState(() => _currentSection = AdminSection.profile),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF805AD5),
              backgroundImage: NetworkImage(_adminProfile?['avatar_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
            ),
          ),
        ],
      ),
    );
  }

  void _performGlobalSearch(String query) async {
    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<Map<String, dynamic>>(
        future: _apiService.globalAdminSearch(query),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const AlertDialog(
              backgroundColor: Color(0xFF1E293B),
              content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xFF805AD5)))),
            );
          }
          final res = snapshot.data!;
          final pts = res['patients'] as List? ?? [];
          final docs = res['doctors'] as List? ?? [];
          final rpts = res['reports'] as List? ?? [];

          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Global Search Results for "$query"', style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: SizedBox(
              width: 450,
              height: 350,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Patients', style: TextStyle(color: Color(0xFF805AD5), fontWeight: FontWeight.bold)),
                    ...pts.map((p) => ListTile(
                          title: Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text(p['email'], style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _currentSection = AdminSection.patients);
                          },
                        )),
                    const Divider(color: Colors.white24),
                    const Text('Doctors', style: TextStyle(color: Color(0xFF3AAFA9), fontWeight: FontWeight.bold)),
                    ...docs.map((d) => ListTile(
                          title: Text(d['name'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text(d['email'], style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _currentSection = AdminSection.doctors);
                          },
                        )),
                    const Divider(color: Colors.white24),
                    const Text('Reports', style: TextStyle(color: Color(0xFFDD6B20), fontWeight: FontWeight.bold)),
                    ...rpts.map((r) => ListTile(
                          title: Text(r['title'], style: const TextStyle(color: Colors.white, fontSize: 13)),
                          subtitle: Text(r['details'], style: const TextStyle(color: Colors.white60, fontSize: 11)),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() => _currentSection = AdminSection.reports);
                          },
                        )),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
            ],
          );
        },
      ),
    );
  }

  // Left Collapsible Sidebar Widget
  Widget _buildSidebarContent() {
    final width = _isSidebarCollapsed ? 80.0 : 250.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: BoxDecoration(
        color: AppTheme.isDark(context) ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Logo & Collapse Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.shield, color: Color(0xFF805AD5), size: 28),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'PlaqueCheck Admin',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(_isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left, color: Colors.white70),
                  onPressed: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 24),
          // Sidebar Nav List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildNavItem(AdminSection.dashboard, 'Dashboard', Icons.dashboard_outlined),
                _buildNavItem(AdminSection.patients, 'Patient Mgmt', Icons.people_outline),
                _buildNavItem(AdminSection.doctors, 'Doctor Mgmt', Icons.medical_services_outlined),
                _buildNavItem(AdminSection.reports, 'Reports', Icons.assignment_outlined),
                _buildNavItem(AdminSection.aiMonitoring, 'AI Monitoring', Icons.psychology_outlined),
                _buildNavItem(AdminSection.analytics, 'Analytics', Icons.bar_chart_outlined),
                _buildNavItem(AdminSection.notifications, 'Notifications', Icons.notifications_outlined),
                _buildNavItem(AdminSection.systemHealth, 'System Health', Icons.monitor_heart_outlined),
                _buildNavItem(AdminSection.auditLogs, 'Audit Logs', Icons.security_outlined),
                _buildNavItem(AdminSection.storage, 'Storage', Icons.cloud_outlined),
                _buildNavItem(AdminSection.settings, 'Settings', Icons.settings_outlined),
                _buildNavItem(AdminSection.profile, 'Profile', Icons.person_outline),
              ],
            ),
          ),
          const Divider(color: Colors.white12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: !_isSidebarCollapsed
                ? const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13))
                : null,
            onTap: _logout,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildNavItem(AdminSection section, String label, IconData icon) {
    final isSelected = _currentSection == section;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF805AD5).withValues(alpha: 0.25) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: const Color(0xFF805AD5).withValues(alpha: 0.5)) : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: isSelected ? const Color(0xFF805AD5) : Colors.white70, size: 20),
        title: !_isSidebarCollapsed
            ? Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              )
            : null,
        onTap: () => setState(() => _currentSection = section),
      ),
    );
  }

  // Active Section View Router
  Widget _buildActiveSectionView() {
    switch (_currentSection) {
      case AdminSection.dashboard:
        return _buildDashboardSection();
      case AdminSection.patients:
        return _buildPatientManagementSection();
      case AdminSection.doctors:
        return _buildDoctorManagementSection();
      case AdminSection.reports:
        return _buildReportManagementSection();
      case AdminSection.aiMonitoring:
        return _buildAiMonitoringSection();
      case AdminSection.analytics:
        return _buildAnalyticsSection();
      case AdminSection.notifications:
        return _buildNotificationsSection();
      case AdminSection.systemHealth:
        return _buildSystemHealthSection();
      case AdminSection.auditLogs:
        return _buildAuditLogsSection();
      case AdminSection.storage:
        return _buildStorageSection();
      case AdminSection.settings:
        return _buildSettingsSection();
      case AdminSection.profile:
        return _buildProfileSection();
    }
  }

  // ================= 1. DASHBOARD SECTION =================
  Widget _buildDashboardSection() {
    final d = _dashboardData ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Administrator Overview', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                Text('Real-time telemetry and ecosystem metrics', style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _triggerExport('all'),
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text('Export Report', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // 16 Real-Time Overview Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 1100 ? 4 : (constraints.maxWidth > 650 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStatCard('Total Patients', '${d["total_patients"] ?? 0}', Icons.people, const Color(0xFF3AAFA9)),
                _buildStatCard('Total Doctors', '${d["total_doctors"] ?? 0}', Icons.medical_services, const Color(0xFF3182CE)),
                _buildStatCard('Active Doctors', '${d["active_doctors"] ?? 0}', Icons.verified, const Color(0xFF38A169)),
                _buildStatCard("Today's New Patients", '${d["today_new_patients"] ?? 0}', Icons.person_add, const Color(0xFFD69E2E)),
                _buildStatCard("Today's Reports", '${d["today_reports"] ?? 0}', Icons.qr_code_scanner, const Color(0xFFDD6B20)),
                _buildStatCard('Pending Reviews', '${d["pending_reviews"] ?? 0}', Icons.hourglass_empty, const Color(0xFFE53E3E)),
                _buildStatCard('Completed Reviews', '${d["completed_reviews"] ?? 0}', Icons.task_alt, const Color(0xFF319795)),
                _buildStatCard('High Risk Cases', '${d["high_risk_cases"] ?? 0}', Icons.warning_amber, const Color(0xFFE53E3E)),
                _buildStatCard('Avg Plaque Score', '${d["average_plaque_score"] ?? 0}%', Icons.analytics, const Color(0xFF805AD5)),
                _buildStatCard('AI Accuracy', '${d["ai_accuracy"] ?? "94.2%"}', Icons.memory, const Color(0xFFD69E2E)),
                _buildStatCard('Total Storage Used', '${d["total_storage_used"] ?? "1.42 GB"}', Icons.cloud, const Color(0xFF3182CE)),
                _buildStatCard('Database Health', '${d["database_health"] ?? "Healthy"}', Icons.dns, const Color(0xFF38A169)),
                _buildStatCard('System Uptime', '${d["system_uptime"] ?? "99.98%"}', Icons.speed, const Color(0xFF3AAFA9)),
                _buildStatCard('Unread Notifications', '${d["unread_notifications"] ?? 0}', Icons.notifications, const Color(0xFFDD6B20)),
                _buildStatCard('Pending Approvals', '${(d["pending_doctors_list"] as List?)?.length ?? 0}', Icons.how_to_reg, const Color(0xFF805AD5)),
                _buildStatCard('System Error Rate', '0.02%', Icons.bug_report, const Color(0xFF38A169)),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        // Recent Activities Feed
        const Text('Recent System Audit Trail', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._auditLogs.take(6).map((log) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderRadius: 14,
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.shield, color: Color(0xFF805AD5), size: 20),
                  title: Text(log['action'] ?? 'ACTION', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${log["details"]} • ${log["timestamp"]}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      borderRadius: 18,
      opacity: 0.14,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 6),
                Expanded(child: Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1)),
              ],
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ================= 2. PATIENT MANAGEMENT =================
  Widget _buildPatientManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Patient Management Portal', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _triggerExport('patients'),
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text('Export Patients CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Search & Filters Bar
        Row(
          children: [
            Expanded(
              child: TextField(
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search Patient ID, Name, Email, Phone...',
                  hintStyle: const TextStyle(color: Colors.white60, fontSize: 12),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF805AD5)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.08),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onChanged: (val) {
                  _patientSearchQuery = val;
                  _loadAllAdminData();
                },
              ),
            ),
            const SizedBox(width: 12),
            DropdownButton<String>(
              value: _patientFilter,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 13),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Patients')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                DropdownMenuItem(value: 'high_risk', child: Text('High Risk')),
                DropdownMenuItem(value: 'pending_review', child: Text('Pending Review')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _patientFilter = val);
                  _loadAllAdminData();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Patients Data Table
        if (_patients.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No patient records found.', style: TextStyle(color: Colors.white70))))
        else
          ..._patients.map((p) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  borderRadius: 16,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: p['high_risk'] ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF3AAFA9).withValues(alpha: 0.3),
                      child: Text(p['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                    title: Row(
                      children: [
                        Text(p['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: p['high_risk'] ? Colors.redAccent.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            p['high_risk'] ? 'HIGH RISK' : 'NORMAL',
                            style: TextStyle(color: p['high_risk'] ? Colors.redAccent : Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${p["patient_id"]} • ${p["email"]} • Phone: ${p["phone"]} • Scans: ${p["total_scans"]}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.visibility, color: Color(0xFF805AD5)),
                          tooltip: 'View Patient Details',
                          onPressed: () => _showPatientDetailModal(p['id']),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white70),
                          color: const Color(0xFF1E293B),
                          onSelected: (action) async {
                            if (action == 'toggle_status') {
                              await _apiService.updatePatientStatus(p['id'], p['status'] == 'active' ? 'deactivated' : 'active');
                              _loadAllAdminData();
                            } else if (action == 'reset_password') {
                              _showResetPasswordDialog(p['id']);
                            } else if (action == 'assign_doctor') {
                              _showAssignDoctorDialog(p['id']);
                            }
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(value: 'toggle_status', child: Text(p['status'] == 'active' ? 'Deactivate' : 'Reactivate', style: const TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'reset_password', child: Text('Reset Password', style: const TextStyle(color: Colors.white))),
                            const PopupMenuItem(value: 'assign_doctor', child: Text('Assign Doctor', style: const TextStyle(color: Colors.white))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  void _showPatientDetailModal(int patientId) async {
    final details = await _apiService.fetchPatientDetails(patientId);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Patient Full Profile #${details["profile"]["user_id"]}', style: const TextStyle(color: Colors.white)),
        content: SizedBox(
          width: 500,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name: ${details["profile"]["name"]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('Email: ${details["profile"]["email"]}', style: const TextStyle(color: Colors.white70)),
                Text('Phone: ${details["profile"]["phone"] ?? "N/A"}', style: const TextStyle(color: Colors.white70)),
                const Divider(color: Colors.white24),
                const Text('Medical History:', style: TextStyle(color: Color(0xFF805AD5), fontWeight: FontWeight.bold)),
                Text(details['medical_history'] ?? 'None', style: const TextStyle(color: Colors.white)),
                const Divider(color: Colors.white24),
                Text('Total Scans Performed: ${details["reports_count"]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: Colors.white70))),
        ],
      ),
    );
  }

  void _showResetPasswordDialog(int userId) {
    final passCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Reset User Password', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: passCtrl,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'New Password', hintStyle: TextStyle(color: Colors.white60)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            onPressed: () async {
              if (passCtrl.text.isNotEmpty) {
                await _apiService.resetUserPassword(userId, passCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset successfully!')));
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAssignDoctorDialog(int patientId) {
    int selectedDocId = 1;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Assign Primary Care Doctor', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select doctor for patient assignment:', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            DropdownButton<int>(
              value: selectedDocId,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Dr. Sarah Jenkins (Periodontics)')),
                DropdownMenuItem(value: 2, child: Text('Dr. Michael Chen (Orthodontics)')),
              ],
              onChanged: (val) {
                if (val != null) selectedDocId = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            onPressed: () async {
              await _apiService.assignDoctorToPatient(patientId, selectedDocId);
              if (!mounted) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Doctor assigned successfully!')));
            },
            child: const Text('Assign', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= 3. DOCTOR MANAGEMENT =================
  Widget _buildDoctorManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Doctor Management & Credentialing', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _triggerExport('doctors'),
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text('Export Doctors CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_doctors.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No doctor accounts registered.', style: TextStyle(color: Colors.white70))))
        else
          ..._doctors.map((d) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  borderRadius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundImage: NetworkImage(d['photo']),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(d['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('${d["qualification"]} • ${d["specialization"]} • Reg: ${d["registration_number"]}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                  Text('${d["clinic_name"]} (${d["hospital_name"]})', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: d['approval_status'] == 'approved' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                d['approval_status'].toString().toUpperCase(),
                                style: TextStyle(color: d['approval_status'] == 'approved' ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Assigned: ${d["patients_assigned"]} pts | Reviewed: ${d["reports_reviewed"]} rpts | Avg Time: ${d["average_review_time"]}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                            Row(
                              children: [
                                if (d['approval_status'] != 'approved')
                                  ElevatedButton.icon(
                                    onPressed: () async {
                                      await _apiService.approveDoctor(d['user_id']);
                                      _loadAllAdminData();
                                    },
                                    icon: const Icon(Icons.check, size: 14, color: Colors.white),
                                    label: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B7A78)),
                                  ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    await _apiService.suspendDoctor(d['user_id']);
                                    _loadAllAdminData();
                                  },
                                  icon: const Icon(Icons.block, size: 14, color: Colors.redAccent),
                                  label: const Text('Suspend', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  // ================= 4. REPORT MANAGEMENT =================
  Widget _buildReportManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Ecosystem Diagnostic Reports', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _triggerExport('reports'),
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text('Export Reports CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_reports.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No diagnostic reports found.', style: TextStyle(color: Colors.white70))))
        else
          ..._reports.map((r) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                  borderRadius: 16,
                  child: ListTile(
                    leading: const Icon(Icons.assignment, color: Color(0xFF805AD5)),
                    title: Text('Report #${r["id"]} - ${r["patient_name"]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Doctor: ${r["doctor_name"]} • Plaque: ${r["plaque_percentage"]}% • Conf: ${r["confidence"]}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: r['severity'].toString().toLowerCase() == 'high' ? Colors.redAccent.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(r['severity'].toString().toUpperCase(), style: TextStyle(color: r['severity'].toString().toLowerCase() == 'high' ? Colors.redAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              )),
      ],
    );
  }

  // ================= 5. AI MONITORING =================
  Widget _buildAiMonitoringSection() {
    final ai = _aiStatus ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI Diagnostic Engine Dashboard', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Model: ${ai["current_model_version"] ?? "v1.4.0"}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showDeployModelDialog(),
                      icon: const Icon(Icons.upload, size: 16, color: Colors.white),
                      label: const Text('Deploy New Model', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Last Training Date: ${ai["last_training_date"]} | Total Inferences: ${ai["inference_count"]}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildAiMetricChip('Detection Accuracy', ai['detection_accuracy'] ?? '94.2%'),
                    const SizedBox(width: 12),
                    _buildAiMetricChip('Avg Confidence', ai['average_confidence'] ?? '95.8%'),
                    const SizedBox(width: 12),
                    _buildAiMetricChip('Avg Processing Time', ai['average_processing_time'] ?? '320 ms'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAiMetricChip(String label, String val) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            const SizedBox(height: 4),
            Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  void _showDeployModelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Deploy / Rollback AI Model', style: TextStyle(color: Colors.white)),
        content: const Text('Select target model version to switch in production engine:', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            onPressed: () async {
              await _apiService.deployAiModel('v1.5.0-RC1');
              if (!mounted) return;
              Navigator.pop(ctx);
              _loadAllAdminData();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('AI Model v1.5.0-RC1 deployed successfully!')));
            },
            child: const Text('Deploy v1.5.0-RC1', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= 6. ANALYTICS =================
  Widget _buildAnalyticsSection() {
    final aly = _analyticsData ?? {};
    final dist = (aly['plaque_severity_distribution'] as Map<String, dynamic>?) ?? {};
    final low = dist['Low (<15%)'] ?? 45;
    final mod = dist['Moderate (15-35%)'] ?? 38;
    final high = dist['High (>35%)'] ?? 17;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Ecosystem Intelligence & Analytics', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Plaque Severity Distribution', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Review Rate: ${aly["review_completion_rate"] ?? "94.6%"}', style: const TextStyle(color: Color(0xFF3AAFA9), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSeverityBar('Low (<15%)', (low as num).toInt(), Colors.greenAccent),
                    _buildSeverityBar('Moderate (15-35%)', (mod as num).toInt(), Colors.orangeAccent),
                    _buildSeverityBar('High (>35%)', (high as num).toInt(), Colors.redAccent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBar(String label, int pct, Color color) {
    return Column(
      children: [
        Text('$pct%', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // ================= 7. NOTIFICATIONS =================
  Widget _buildNotificationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('System Notifications & Broadcasts', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showBroadcastDialog(),
              icon: const Icon(Icons.campaign, size: 16, color: Colors.white),
              label: const Text('Send Broadcast Announcement', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._notifications.map((n) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: GlassCard(
                borderRadius: 16,
                child: ListTile(
                  leading: const Icon(Icons.notifications_active, color: Color(0xFF805AD5)),
                  title: Text(n['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text('${n["message"]} • Target: ${n["target"]}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ),
              ),
            )),
      ],
    );
  }

  void _showBroadcastDialog() {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String targetRole = 'all';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Send Broadcast Announcement', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Notification Title', hintStyle: TextStyle(color: Colors.white60))),
            const SizedBox(height: 10),
            TextField(controller: msgCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Message Body', hintStyle: TextStyle(color: Colors.white60))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && msgCtrl.text.isNotEmpty) {
                await _apiService.sendBroadcastNotification(targetRole: targetRole, title: titleCtrl.text, message: msgCtrl.text);
                if (!mounted) return;
                Navigator.pop(ctx);
                _loadAllAdminData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast sent successfully!')));
              }
            },
            child: const Text('Send Broadcast', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ================= 8. SYSTEM HEALTH =================
  Widget _buildSystemHealthSection() {
    final sys = _systemHealth ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Infrastructure & System Health', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Backend API: ${sys["backend_status"] ?? "Online"}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Supabase Realtime: ${sys["supabase_status"] ?? "Connected"}', style: const TextStyle(color: Colors.white70)),
                Text('API Response Time: ${sys["api_response_time"] ?? "42 ms"} | DB Response: ${sys["database_response_time"] ?? "1.2 ms"}', style: const TextStyle(color: Colors.white70)),
                Text('Last Backup: ${sys["last_backup"]}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= 9. AUDIT LOGS =================
  Widget _buildAuditLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Security Audit & Access Logs', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _triggerExport('audit_logs'),
              icon: const Icon(Icons.download, size: 16, color: Colors.white),
              label: const Text('Export Audit Logs CSV', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._auditLogs.map((l) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                borderRadius: 14,
                child: ListTile(
                  leading: const Icon(Icons.shield, color: Color(0xFF805AD5)),
                  title: Text(l['action'] ?? 'ACTION', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text('${l["details"]} • ${l["timestamp"]}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                ),
              ),
            )),
      ],
    );
  }

  // ================= 10. STORAGE =================
  Widget _buildStorageSection() {
    final stg = _storageStats ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Supabase Storage Analytics', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Storage Used: ${stg["supabase_storage_usage"] ?? "1.42 GB"}', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total Images: ${stg["total_images"] ?? 1284} | Avg Image Size: ${stg["average_image_size"] ?? "1.12 MB"}', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= 11. SETTINGS =================
  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrator System Settings', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 20,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.security, color: Color(0xFF805AD5)),
                  title: const Text('User & Role Security Policies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Enforce role-based access control and token expiration rules.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () {},
                ),
                const Divider(color: Colors.white12),
                ListTile(
                  leading: const Icon(Icons.storage, color: Color(0xFF3AAFA9)),
                  title: const Text('Database & Backup Configuration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Manage automated daily Supabase backup targets.', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white70),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= 12. PROFILE =================
  Widget _buildProfileSection() {
    final prof = _adminProfile ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Administrator Profile & Security', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GlassCard(
          borderRadius: 24,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: NetworkImage(prof['avatar_url'] ?? 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150'),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prof['name'] ?? 'System Administrator', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        Text('${prof["role"]} • ${prof["organization"]}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('Email: ${prof["email"]}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => _showResetPasswordDialog(prof['id'] ?? 1),
                  icon: const Icon(Icons.key, color: Colors.white, size: 16),
                  label: const Text('Change Administrator Password', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF805AD5)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

