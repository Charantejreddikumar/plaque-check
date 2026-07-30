import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _dashboardData;
  SessionUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final user = await SessionManager.currentUser();
      final data = await _apiService.fetchDoctorDashboard();
      if (!mounted) return;
      setState(() {
        _user = user;
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${_monthName(now.month)} ${now.day}, ${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}';

    return DoctorNavScaffold(
      currentRoute: '/doctor-dashboard',
      title: 'PlaqueCheck Clinical Dashboard',
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner Header
              GlassCard(
                borderRadius: 24,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.accent(context).withValues(alpha: 0.2),
                        child: Icon(Icons.person_rounded, color: AppTheme.accent(context), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, Dr. ${_user?.fullName ?? "Dentist"} 👋',
                              style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Specialty: Periodontics & Oral Surgery • PlaqueCheck Dental Suite',
                              style: TextStyle(
                                color: AppTheme.textSecondary(context),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: AppTheme.textSecondary(context),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: AppTheme.accent(context),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              if (_isLoading) ...[
                Center(child: CircularProgressIndicator(color: AppTheme.accent(context))),
              ] else ...[
                // Quick Overview Metrics Grid
                GridView.count(
                  crossAxisCount: MediaQuery.of(context).size.width > 1200 ? 4 : 2,
                  shrinkWrap: true,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.6,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _OverviewMetricCard(
                      title: "Today's Patients",
                      value: '${_dashboardData?["total_patients"] ?? 0}',
                      icon: Icons.people_alt_rounded,
                      color: AppTheme.accent(context),
                    ),
                    _OverviewMetricCard(
                      title: 'Pending Reviews',
                      value: '${_dashboardData?["pending_reviews"] ?? 0}',
                      icon: Icons.pending_actions_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                    _OverviewMetricCard(
                      title: 'High Risk Cases',
                      value: '${_dashboardData?["high_risk_patients"] ?? 0}',
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    _OverviewMetricCard(
                      title: 'Avg Plaque Score',
                      value: '${_dashboardData?["average_plaque_score"] ?? 0}%',
                      icon: Icons.analytics_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Quick Action Buttons Row
                Text(
                  'Quick Clinical Actions',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Review Queue',
                        icon: Icons.rate_review_rounded,
                        color: AppTheme.accent(context),
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Search Patients',
                        icon: Icons.person_search_rounded,
                        color: const Color(0xFF10B981),
                        onTap: () => Navigator.pushNamed(context, '/doctor-patients'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'View Analytics',
                        icon: Icons.insights_rounded,
                        color: const Color(0xFF805AD5),
                        onTap: () => Navigator.pushNamed(context, '/doctor-analytics'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Pending Reviews Queue Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Dental Scans Waiting for Doctor Sign-Off',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/doctor-patients'),
                      icon: Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.accent(context)),
                      label: Text('View All Patients', style: TextStyle(color: AppTheme.accent(context))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if ((_dashboardData?["pending_reports_list"] as List?)?.isEmpty ?? true) ...[
                  GlassCard(
                    borderRadius: 20,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No patient reports available.',
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ...((_dashboardData?["pending_reports_list"] as List? ?? []).map((r) => _PendingReportCard(
                        report: r,
                        onReview: () => Navigator.pushNamed(context, '/doctor-review', arguments: r['report_id']).then((_) => _loadData()),
                      ))),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _OverviewMetricCard extends StatelessWidget {
  const _OverviewMetricCard({
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
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 18,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingReportCard extends StatelessWidget {
  const _PendingReportCard({required this.report, required this.onReview});

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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: plaque >= 50 ? Colors.redAccent.withValues(alpha: 0.2) : AppTheme.accent(context).withValues(alpha: 0.2),
                ),
                child: Center(
                  child: Text(
                    '$plaque%',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dental Report #${report["report_id"]}',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patient User #${report["user_id"]} • Status: ${report["review_status"]}',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onReview,
                icon: const Icon(Icons.rate_review_rounded, size: 16),
                label: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
