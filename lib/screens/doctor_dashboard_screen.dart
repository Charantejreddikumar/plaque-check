import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _dashboardData;
  List<dynamic> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchDoctorDashboard();
      if (!mounted) return;
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _isSearching = true);
    try {
      final results = await _apiService.searchPatients(query);
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSearching = false);
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
            onRefresh: _loadDashboard,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Doctor Header Bar
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B7A78).withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.medical_services, color: Color(0xFF3AAFA9), size: 28),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doctor Clinical Dashboard',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              'PlaqueCheck Dental AI Network',
                              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                            ),
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
                    // Doctor Metrics Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.45,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MetricCard(
                          title: "Today's Pending Reviews",
                          value: '${_dashboardData?["pending_reviews"] ?? 0}',
                          icon: Icons.pending_actions_outlined,
                          color: const Color(0xFFE53E3E),
                        ),
                        _MetricCard(
                          title: 'Total Patients',
                          value: '${_dashboardData?["total_patients"] ?? 0}',
                          icon: Icons.people_outline,
                          color: const Color(0xFF3AAFA9),
                        ),
                        _MetricCard(
                          title: 'High Risk Patients',
                          value: '${_dashboardData?["high_risk_patients"] ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFDD6B20),
                        ),
                        _MetricCard(
                          title: 'Average Plaque Score',
                          value: '${_dashboardData?["average_plaque_score"] ?? 0}%',
                          icon: Icons.analytics_outlined,
                          color: const Color(0xFF3182CE),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Patient Directory Search
                    const Text(
                      'Search Patients Directory',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search by Patient ID, Name, Email, or Phone...',
                        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFF3AAFA9)),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.08),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    if (_isSearching) ...[
                      const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator())),
                    ] else if (_searchResults.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ..._searchResults.map((p) => _PatientTile(patient: p)),
                    ],

                    const SizedBox(height: 28),

                    // Pending Reviews Queue Section
                    const Text(
                      'Pending Reports Queue for Clinical Review',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    if ((_dashboardData?["pending_reports_list"] as List?)?.isEmpty ?? true) ...[
                      GlassCard(
                        borderRadius: 20,
                        child: const Center(
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Text(
                              'No pending reports waiting for review. Hygiene status clear!',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      ...((_dashboardData?["pending_reports_list"] as List? ?? []).map((r) => _PendingReportTile(
                            report: r,
                            onReview: () => Navigator.pushNamed(context, '/doctor-review', arguments: r['report_id']).then((_) => _loadDashboard()),
                          ))),
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      opacity: 0.14,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});

  final Map<String, dynamic> patient;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 16,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF2B7A78),
          child: Text(patient['name']?[0] ?? 'P', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(patient['name'] ?? 'Patient', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('ID: #${patient["id"]} • ${patient["email"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF3AAFA9)),
      ),
    );
  }
}

class _PendingReportTile extends StatelessWidget {
  const _PendingReportTile({required this.report, required this.onReview});

  final Map<String, dynamic> report;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final plaque = report['plaque_percent'] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        borderRadius: 20,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: plaque >= 50 ? Colors.red.withValues(alpha: 0.2) : const Color(0xFF3AAFA9).withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text('$plaque%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scan Report #${report["report_id"]}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Patient User #${report["user_id"]} • Status: ${report["review_status"]}', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onReview,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2B7A78), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
