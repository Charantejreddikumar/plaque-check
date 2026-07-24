import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/plaque_prediction.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_image.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  late final Future<List<_ComparisonReport>> _reportsFuture = _loadReports();
  final ApiService _apiService = ApiService();

  Future<List<_ComparisonReport>> _loadReports() async {
    try {
      final backendReports = await _apiService.fetchReports();
      if (backendReports.length >= 2) {
        return backendReports.map(_ComparisonReport.fromScanReport).toList();
      }
    } catch (_) {
      // Local reports keep comparison available when the backend is offline.
    }

    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList('scan_reports') ?? [];
    return values
        .map((value) {
          try {
            return _ComparisonReport.fromJson(jsonDecode(value));
          } catch (_) {
            return null;
          }
        })
        .whereType<_ComparisonReport>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: AppTheme.pageDecoration(context),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0EA5E9)),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Scan Comparison',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Compare previous and current reports when history is available.',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                FutureBuilder<List<_ComparisonReport>>(
                  future: _reportsFuture,
                  builder: (context, snapshot) {
                    final reports = snapshot.data ?? [];
                    if (reports.length < 2) {
                      return const _EmptyComparison();
                    }
                    final previous = reports[1];
                    final current = reports.first;

                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _ComparisonImage(
                                label: 'Previous scan',
                                report: previous,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _ComparisonImage(
                                label: 'Current scan',
                                report: current,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _ComparisonSummary(
                          previous: previous,
                          current: current,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ComparisonImage extends StatelessWidget {
  const _ComparisonImage({required this.label, required this.report});

  final String label;
  final _ComparisonReport report;

  @override
  Widget build(BuildContext context) {
    final imagePath = report.processedImage.isNotEmpty
        ? report.processedImage
        : report.imagePath;
    final imageUrl = report.isBackend
        ? ApiService().mediaUrl(imagePath)
        : imagePath;

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 0.82,
              child: imagePath.isNotEmpty && report.isBackend
                  ? buildNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : imagePath.isNotEmpty
                  ? buildPlatformImage(imagePath: imagePath, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withValues(alpha: 0.10),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        color: Color(0xFF38BDF8),
                        size: 34,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Plaque ${report.plaque}% - ${report.severity}',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonSummary extends StatelessWidget {
  const _ComparisonSummary({required this.previous, required this.current});

  final _ComparisonReport previous;
  final _ComparisonReport current;

  @override
  Widget build(BuildContext context) {
    final plaqueDiff = current.plaque - previous.plaque;
    final scoreDiff = current.score - previous.score;
    final improved = plaqueDiff <= 0 && scoreDiff >= 0;
    final indicatorColor = improved
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);
    final indicatorIcon = improved
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;
    final indicatorText = improved ? 'Improvement' : 'Decline';

    return GlassCard(
      borderRadius: 30,
      opacity: 0.15,
      borderOpacity: 0.24,
      glowColor: const Color(0xFF0EA5E9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(indicatorIcon, color: indicatorColor, size: 22),
              const SizedBox(width: 10),
              Text(
                indicatorText,
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DiffRow(
            label: 'Previous report',
            value: 'Plaque ${previous.plaque}% - Score ${previous.score}',
          ),
          const SizedBox(height: 10),
          _DiffRow(
            label: 'Current report',
            value: 'Plaque ${current.plaque}% - Score ${current.score}',
          ),
          const SizedBox(height: 10),
          _DiffRow(
            label: 'Plaque difference',
            value: _signedPercent(plaqueDiff),
            valueColor: plaqueDiff <= 0
                ? const Color(0xFF34D399)
                : const Color(0xFFF87171),
          ),
          const SizedBox(height: 10),
          _DiffRow(
            label: 'Oral health score difference',
            value: _signedNumber(scoreDiff),
            valueColor: scoreDiff >= 0
                ? const Color(0xFF34D399)
                : const Color(0xFFF87171),
          ),
          const SizedBox(height: 10),
          _DiffRow(
            label: 'Risk level comparison',
            value: '${previous.severity} -> ${current.severity}',
          ),
        ],
      ),
    );
  }
}

class _DiffRow extends StatelessWidget {
  const _DiffRow({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(17),
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
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppTheme.textPrimary(context),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyComparison extends StatelessWidget {
  const _EmptyComparison();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 30,
      child: Column(
        children: [
          Icon(
            Icons.compare_outlined,
            color: AppTheme.accent(context),
            size: 44,
          ),
          const SizedBox(height: 12),
          Text(
            'No comparison available',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Save at least two reports to compare previous and current scans.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonReport {
  const _ComparisonReport({
    required this.imagePath,
    required this.processedImage,
    required this.plaque,
    required this.severity,
    required this.score,
    required this.isBackend,
  });

  factory _ComparisonReport.fromJson(Map<String, dynamic> json) {
    return _ComparisonReport(
      imagePath: json['imagePath'] as String? ?? '',
      processedImage: json['processedImage'] as String? ?? '',
      plaque: json['plaque'] as int? ?? 0,
      severity: json['severity'] as String? ?? 'Pending',
      score: json['score'] as int? ?? 0,
      isBackend: false,
    );
  }

  factory _ComparisonReport.fromScanReport(ScanReport report) {
    return _ComparisonReport(
      imagePath: report.imagePath,
      processedImage: report.processedImage,
      plaque: report.plaque,
      severity: report.severity,
      score: report.score,
      isBackend: report.isBackend,
    );
  }

  final String imagePath;
  final String processedImage;
  final int plaque;
  final String severity;
  final int score;
  final bool isBackend;
}

String _signedPercent(int value) {
  return '${value > 0 ? '+' : ''}$value%';
}

String _signedNumber(int value) {
  return '${value > 0 ? '+' : ''}$value';
}
