import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_side_nav.dart';
import '../widgets/glass_card.dart';

class DoctorAnalyticsScreen extends StatefulWidget {
  const DoctorAnalyticsScreen({super.key});

  @override
  State<DoctorAnalyticsScreen> createState() => _DoctorAnalyticsScreenState();
}

class _DoctorAnalyticsScreenState extends State<DoctorAnalyticsScreen> {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.fetchDoctorAnalytics();
      if (!mounted) return;
      setState(() {
        _analyticsData = res;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final daily = (_analyticsData?['daily_reviews'] as List?) ?? [];

    return DoctorNavScaffold(
      currentRoute: '/doctor-analytics',
      title: 'Clinical Performance & Analytics',
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppTheme.accent(context)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clinical Performance & AI Analytics',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review volume trends, plaque severity breakdown, and completion efficiency.',
                    style: TextStyle(
                      color: AppTheme.textSecondary(context),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Completion Rate Card
                  GlassCard(
                    borderRadius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            ),
                            child: const Icon(Icons.task_alt_rounded, color: Color(0xFF10B981), size: 32),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Review Completion Efficiency Rate',
                                  style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                                ),
                                Text(
                                  '${_analyticsData?["review_completion_rate"] ?? 0.0}%',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary(context),
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
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

                  // Daily Review Distribution Chart Representation
                  Text(
                    'Weekly Review Count Distribution',
                    style: TextStyle(
                      color: AppTheme.textPrimary(context),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    borderRadius: 22,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: (_analyticsData?['total_reports'] ?? 0) == 0
                          ? Center(
                              child: Text(
                                'No patient reports available.',
                                style: TextStyle(
                                  color: AppTheme.textPrimary(context),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: daily.map((d) {
                                    final int count = d['count'] ?? 0;
                                    final double barHeight = (count * 6.0).clamp(20.0, 160.0);
                                    return Column(
                                      children: [
                                        Text(
                                          '$count',
                                          style: TextStyle(
                                            color: AppTheme.accent(context),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        AnimatedContainer(
                                          duration: const Duration(milliseconds: 300),
                                          width: 24,
                                          height: barHeight,
                                          decoration: BoxDecoration(
                                            color: AppTheme.accent(context),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          d['day'] ?? '',
                                          style: TextStyle(
                                            color: AppTheme.textSecondary(context),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
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
