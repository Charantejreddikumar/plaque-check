import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/plaque_prediction.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_glass_nav.dart';
import '../widgets/glass_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedTabIndex = 0;
  late Future<List<_DashboardReport>> _reportsFuture = _loadReports();
  late final Future<SessionUser?> _userFuture = SessionManager.currentUser();
  final ApiService _apiService = ApiService();

  Future<List<_DashboardReport>> _loadReports() async {
    List<ScanReport> backendReports = [];
    try {
      backendReports = await _apiService.fetchReports();
    } catch (_) {}

    final values = await SessionManager.getReportsForCurrentUser();
    final localReports = values
        .map((value) {
          try {
            return ScanReport.fromLocalJson(jsonDecode(value));
          } catch (_) {
            return null;
          }
        })
        .whereType<ScanReport>()
        .toList();

    final Map<String, ScanReport> uniqueReports = {};
    for (final report in [...backendReports, ...localReports]) {
      final key =
          '${report.date.year}-${report.date.month}-${report.date.day}-${report.date.hour}-${report.date.minute}_${report.plaque}_${report.severity}';
      if (!uniqueReports.containsKey(key)) {
        uniqueReports[key] = report;
      }
    }

    final combined = uniqueReports.values.toList();
    combined.sort((a, b) => b.date.compareTo(a.date));

    return combined.map(_DashboardReport.fromScanReport).toList();
  }


  Future<void> _openScan() async {
    await Navigator.pushNamed(context, '/scan-instructions');
    if (!mounted) {
      return;
    }
    setState(() {
      _reportsFuture = _loadReports();
    });
  }

  void _handleTabSelected(int index) {
    setState(() => _selectedTabIndex = index);

    if (index == 1) {
      _openScan();
    } else if (index == 2) {
      Navigator.pushNamed(context, '/history');
    } else if (index == 3) {
      Navigator.pushNamed(context, '/profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_DashboardReport>>(
      future: _reportsFuture,
      builder: (context, snapshot) {
        final reports = snapshot.data ?? [];
        final latestReport = reports.isEmpty ? null : reports.first;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: AppTheme.pageDecoration(context),
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 128),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeaderProfile(reports),
                          const SizedBox(height: 24),
                          _buildOralScoreIndexCard(latestReport),
                          const SizedBox(height: 26),
                          _buildPrimaryScanCta(),
                          const SizedBox(height: 26),
                          _buildDiagnosticsAnalysisCard(latestReport),
                          const SizedBox(height: 24),
                          _buildWeeklyProgressionCard(reports),
                          const SizedBox(height: 24),
                          _buildAICoachCard(latestReport),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 98,
                    right: 24,
                    child: _FloatingScanButton(onTap: _openScan),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: BottomGlassNavigation(
                      selectedIndex: _selectedTabIndex,
                      onTabSelected: _handleTabSelected,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderProfile(List<_DashboardReport> reports) {
    final hasHistory = reports.isNotEmpty;
    return GlassCard(
      borderRadius: 26,
      padding: const EdgeInsets.all(18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF69C7C3), Color(0xFF69C7C3)],
                    ),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  alignment: Alignment.center,
                  child: _UserInitials(userFuture: _userFuture),
                ),
                const SizedBox(width: 13),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Welcome back,',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary(context),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _UserName(
                        userFuture: _userFuture,
                        textColor: AppTheme.textPrimary(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.pushNamed(context, '/history'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: (hasHistory ? AppTheme.accent(context) : Colors.white)
                    .withValues(alpha: hasHistory ? 0.14 : 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: Row(
                children: [
                  Icon(
                    hasHistory
                        ? Icons.history_edu_outlined
                        : Icons.info_outline_rounded,
                    color: AppTheme.accentSoft(context),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    hasHistory
                        ? '${reports.length} saved scan(s)'
                        : 'No scan history yet',
                    style: TextStyle(
                      color: AppTheme.accentSoft(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right,
                    color: AppTheme.accentSoft(context),
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOralScoreIndexCard(_DashboardReport? report) {
    final hasReport = report != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
        ),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2B7A78).withValues(alpha: 0.26),
            blurRadius: 46,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: const Color(0xFF3BA7A4).withValues(alpha: 0.12),
            blurRadius: 34,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -28,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ORAL DIAGNOSTIC STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  hasReport
                      ? 'Latest saved diagnostic report'
                      : 'Awaiting diagnostic analysis',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 88,
                          height: 88,
                          child: CircularProgressIndicator(
                            value: hasReport ? report.score / 100 : 0,
                            strokeWidth: 8,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.14,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              hasReport ? '${report.score}' : '--',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              hasReport ? 'SCORE' : 'NO DATA',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasReport
                                ? 'Plaque ${report.plaque}% - ${report.severity}'
                                : 'Complete your first scan',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            hasReport
                                ? 'Displaying your most recently saved local report. Backend synchronization can populate this card later.'
                                : 'No clinical score is shown until an AI analysis is completed and saved.',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryScanCta() {
    return GestureDetector(
      onTap: _openScan,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF5FBFC), Color(0xFF69C7C3)],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF69C7C3).withValues(alpha: 0.22),
              blurRadius: 42,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              color: Colors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              'Start AI Plaque Scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressionCard(List<_DashboardReport> reports) {
    final hasHistory = reports.isNotEmpty;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: AppTheme.accentSoft(context),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Weekly Biofilm Progression',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasHistory)
            _EmptyChartPlaceholder(textColor: AppTheme.textSecondary(context))
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _buildHistoryBars(reports),
            ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsAnalysisCard(_DashboardReport? report) {
    return GlassCard(
      borderRadius: 30,
      opacity: 0.14,
      borderOpacity: 0.24,
      glowColor: const Color(0xFF2B7A78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medical_information_outlined,
                color: AppTheme.accentSoft(context),
                size: 19,
              ),
              const SizedBox(width: 8),
              Text(
                'Diagnostics Analysis',
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (report == null)
            _DiagnosticPlaceholder(textColor: AppTheme.textSecondary(context))
          else
            Column(
              children: [
                _DiagnosticRow(
                  label: 'Plaque Percentage',
                  value: '${report.plaque}%',
                ),
                const SizedBox(height: 10),
                _DiagnosticRow(
                  label: 'Oral Health Score',
                  value: '${report.score}',
                ),
                const SizedBox(height: 10),
                _DiagnosticRow(label: 'Risk Level', value: report.severity),
                const SizedBox(height: 10),
                _DiagnosticRow(
                  label: 'Scan Date',
                  value: _formatDashboardDate(report.date),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildHistoryBars(List<_DashboardReport> reports) {
    final recent = reports.take(7).toList().reversed.toList();
    return recent
        .map(
          (report) => _buildBar(
            '${report.date.month}/${report.date.day}',
            report.plaque.toDouble().clamp(8, 100),
            report == reports.first,
          ),
        )
        .toList();
  }

  Widget _buildBar(String day, double heightPercent, bool isHighlight) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 22,
            height: heightPercent * 0.62,
            decoration: BoxDecoration(
              gradient: isHighlight
                  ? const LinearGradient(
                      colors: [Color(0xFF2B7A78), Color(0xFF3BA7A4)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    )
                  : LinearGradient(
                      colors: [
                        AppTheme.textSecondary(context).withValues(alpha: 0.8),
                        AppTheme.textSecondary(context).withValues(alpha: 0.35),
                      ],
                    ),
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          day,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppTheme.textSecondary(context),
          ),
        ),
      ],
    );
  }

  Widget _buildAICoachCard(_DashboardReport? report) {
    return GlassCard(
      opacity: 0.13,
      borderOpacity: 0.22,
      glowColor: const Color(0xFF3BA7A4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3BA7A4), Color(0xFF3BA7A4)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Icon(Icons.bolt, color: Color(0xFF69C7C3), size: 21),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A.I. HEALTH COACH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accentSoft(context),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  report == null
                      ? 'Complete and save a scan to unlock personalized coaching based on real diagnostic history.'
                      : 'Latest local report is available. Personalized coaching will use backend-validated trends when connected.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary(context),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingScanButton extends StatelessWidget {
  const _FloatingScanButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2B7A78).withValues(alpha: 0.34),
              blurRadius: 34,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
      ),
    );
  }
}

class _UserInitials extends StatelessWidget {
  const _UserInitials({required this.userFuture});

  final Future<SessionUser?> userFuture;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionUser?>(
      future: userFuture,
      builder: (context, snapshot) {
        return Text(
          snapshot.data?.initials ?? 'PC',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        );
      },
    );
  }
}

class _UserName extends StatelessWidget {
  const _UserName({required this.userFuture, required this.textColor});

  final Future<SessionUser?> userFuture;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SessionUser?>(
      future: userFuture,
      builder: (context, snapshot) {
        final name = snapshot.data?.fullName.trim();
        return Text(
          name?.isNotEmpty == true ? name! : 'PlaqueCheck User',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: TextStyle(
            fontSize: 17,
            color: textColor,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        );
      },
    );
  }
}

class _EmptyChartPlaceholder extends StatelessWidget {
  const _EmptyChartPlaceholder({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart_rounded, color: textColor, size: 34),
          const SizedBox(height: 10),
          Text(
            'No diagnostic history available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosticPlaceholder extends StatelessWidget {
  const _DiagnosticPlaceholder({required this.textColor});

  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        'No diagnostic data available yet.\nPerform a scan to generate diagnostics.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1.45,
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  const _DiagnosticRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardReport {
  const _DashboardReport({
    required this.date,
    required this.plaque,
    required this.severity,
    required this.score,
  });

  // ignore: unused_element
  factory _DashboardReport.fromJson(Map<String, dynamic> json) {

    return _DashboardReport(
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      plaque: json['plaque'] as int? ?? 0,
      severity: json['severity'] as String? ?? 'Unknown',
      score: json['score'] as int? ?? 0,
    );
  }

  factory _DashboardReport.fromScanReport(ScanReport report) {
    return _DashboardReport(
      date: report.date,
      plaque: report.plaque,
      severity: report.severity,
      score: report.score,
    );
  }

  final DateTime date;
  final int plaque;
  final String severity;
  final int score;
}

String _formatDashboardDate(DateTime date) {
  return '${date.month}/${date.day}/${date.year}';
}
