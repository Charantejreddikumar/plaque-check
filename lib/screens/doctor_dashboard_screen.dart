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

  String? _loadError;

  Future<void> _loadData() async {
    debugPrint('[DIAGNOSTIC] DOCTOR DASHBOARD FETCH START');
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        SessionManager.currentUser(),
        _apiService.fetchDoctorDashboard().catchError((e) {
          debugPrint('[DIAGNOSTIC] fetchDoctorDashboard error: $e');
          return <String, dynamic>{};
        }),
      ]).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('[DIAGNOSTIC] DOCTOR DASHBOARD FETCH TIMEOUT');
          return [null, {}];
        },
      );

      if (!mounted) return;
      setState(() {
        _user = results[0] as SessionUser?;
        _dashboardData = results[1] as Map<String, dynamic>;
      });
      debugPrint('[DIAGNOSTIC] DOCTOR DASHBOARD FETCH COMPLETE');
    } catch (e) {
      debugPrint('[DIAGNOSTIC] DOCTOR DASHBOARD FETCH ERROR: $e');
      if (!mounted) return;
      setState(() {
        _loadError = 'Failed to load doctor dashboard. Tap to retry.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${_monthName(now.month)} ${now.day}, ${now.year}';
    final timeStr = '${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}';

    final todaysPatients = (_dashboardData?["todays_patients"] as List?) ?? [];
    final pendingQueue = (_dashboardData?["pending_reports_list"] as List?) ?? [];
    final highRiskCases = (_dashboardData?["high_risk_cases"] as List?) ?? [];

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
                      title: "Today's Scans",
                      value: '${todaysPatients.length}',
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

                // SECTION 1: TODAY'S PATIENTS
                Text(
                  "Today's Patients Scans & Reviews",
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (todaysPatients.isEmpty) ...[
                  GlassCard(
                    borderRadius: 18,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          "No patients for today.",
                          style: TextStyle(
                            color: AppTheme.textPrimary(context),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  ...todaysPatients.map((r) => _ReportRowCard(
                        report: r,
                        onReview: () => Navigator.pushNamed(context, '/doctor-review', arguments: r['report_id']).then((_) => _loadData()),
                      )),
                ],
                const SizedBox(height: 28),

                // SECTION 2: HIGH RISK CASES (>= 50% Plaque)
                if (highRiskCases.isNotEmpty) ...[
                  Text(
                    'High Risk Cases (>= 50% Plaque Score)',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...highRiskCases.take(5).map((r) => _ReportRowCard(
                        report: r,
                        isHighRisk: true,
                        onReview: () => Navigator.pushNamed(context, '/doctor-review', arguments: r['report_id']).then((_) => _loadData()),
                      )),
                  const SizedBox(height: 28),
                ],

                // SECTION 3: PENDING REVIEWS QUEUE (Ordered by Risk & Upload Date)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pending Clinical Review Queue',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/doctor-patients'),
                      icon: Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.accent(context)),
                      label: Text('View Directory', style: TextStyle(color: AppTheme.accent(context))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (pendingQueue.isEmpty) ...[
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
                  ...pendingQueue.map((r) => _ReportRowCard(
                        report: r,
                        onReview: () => Navigator.pushNamed(context, '/doctor-review', arguments: r['report_id']).then((_) => _loadData()),
                      )),
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

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({
    required this.report,
    required this.onReview,
    this.isHighRisk = false,
  });

  final Map<String, dynamic> report;
  final VoidCallback onReview;
  final bool isHighRisk;

  @override
  Widget build(BuildContext context) {
    final plaque = report['plaque_percent'] ?? 0;
    final patientName = report['patient_name'] ?? 'Patient #${report["user_id"]}';
    final timestamp = (report['timestamp'] ?? '').toString();

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
                  color: (plaque >= 50 || isHighRisk)
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : AppTheme.accent(context).withValues(alpha: 0.2),
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
                      patientName,
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan #${report["report_id"]} • Status: ${report["review_status"]} • Uploaded: $timestamp',
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
