import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _adminData;
  List<dynamic> _doctors = [];
  List<dynamic> _auditLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await _apiService.fetchAdminDashboard();
      final docs = await _apiService.fetchDoctorsList();
      final logs = await _apiService.fetchAuditLogs();

      if (!mounted) return;
      setState(() {
        _adminData = dashboard;
        _doctors = docs;
        _auditLogs = logs;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveDoctor(int userId) async {
    try {
      await _apiService.approveDoctor(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor account approved successfully!')),
      );
      _loadAdminData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '').trim())),
      );
    }
  }

  Future<void> _deactivateDoctor(int userId) async {
    try {
      await _apiService.deactivateDoctor(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor account deactivated.')),
      );
      _loadAdminData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('ApiException: ', '').trim())),
      );
    }
  }

  Future<void> _logout() async {
    await SessionManager.clearSession();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: _loadAdminData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Admin Header Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B7A78).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Color(0xFF3AAFA9), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('System Admin Panel', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('PlaqueCheck Healthcare Core', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.white70),
                        tooltip: 'Logout',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (_isLoading) ...[
                    const Center(child: CircularProgressIndicator(color: Color(0xFF3AAFA9))),
                  ] else ...[
                    // Admin Analytics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.45,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _AdminStatCard(title: 'Total Users', value: '${_adminData?["total_users"] ?? 0}', icon: Icons.group_outlined, color: const Color(0xFF3AAFA9)),
                        _AdminStatCard(title: 'Total Doctors', value: '${_adminData?["total_doctors"] ?? 0}', icon: Icons.medical_services_outlined, color: const Color(0xFF3182CE)),
                        _AdminStatCard(title: "Today's Scans", value: '${_adminData?["today_scans"] ?? 0}', icon: Icons.qr_code_scanner, color: const Color(0xFFDD6B20)),
                        _AdminStatCard(title: 'Model Version', value: '${_adminData?["model_version"] ?? "v1.4"}', icon: Icons.memory_outlined, color: const Color(0xFF805AD5)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Doctor Approvals Queue
                    const Text('Doctor Registration Requests', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_doctors.isEmpty) ...[
                      GlassCard(
                        borderRadius: 20,
                        child: const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No doctor accounts registered.', style: TextStyle(color: Colors.white70)))),
                      ),
                    ] else ...[
                      ..._doctors.map((doc) => _DoctorApprovalTile(
                            doctor: doc,
                            onApprove: () => _approveDoctor(doc['user_id']),
                            onDeactivate: () => _deactivateDoctor(doc['user_id']),
                          )),
                    ],

                    const SizedBox(height: 28),

                    // Audit Logs Section
                    const Text('System Security & Audit Logs', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),

                    if (_auditLogs.isEmpty) ...[
                      GlassCard(
                        borderRadius: 20,
                        child: const Center(child: Padding(padding: EdgeInsets.all(16), child: Text('No audit events logged.', style: TextStyle(color: Colors.white70)))),
                      ),
                    ] else ...[
                      ..._auditLogs.take(8).map((log) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: GlassCard(
                              borderRadius: 14,
                              child: ListTile(
                                dense: true,
                                leading: const Icon(Icons.shield_outlined, color: Color(0xFF3AAFA9), size: 20),
                                title: Text(log['action'] ?? 'ACTION', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                                subtitle: Text('${log["details"]} • ${log["timestamp"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                              ),
                            ),
                          )),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({required this.title, required this.value, required this.icon, required this.color});

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      opacity: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11), maxLines: 1)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _DoctorApprovalTile extends StatelessWidget {
  const _DoctorApprovalTile({required this.doctor, required this.onApprove, required this.onDeactivate});

  final Map<String, dynamic> doctor;
  final VoidCallback onApprove;
  final VoidCallback onDeactivate;

  @override
  Widget build(BuildContext context) {
    final status = doctor['approval_status'] ?? 'pending_approval';
    final isApproved = status == 'approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Dr. ${doctor["name"]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: isApproved ? Colors.greenAccent : Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${doctor["specialization"]} • Reg: ${doctor["registration_number"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              Text('${doctor["clinic_name"]} (${doctor["hospital_name"]})', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isApproved) ...[
                    ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 16, color: Colors.white),
                      label: const Text('Approve', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B7A78)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  OutlinedButton.icon(
                    onPressed: onDeactivate,
                    icon: const Icon(Icons.block, size: 16, color: Colors.redAccent),
                    label: const Text('Deactivate', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
