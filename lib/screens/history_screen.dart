import 'dart:convert';

import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/plaque_prediction.dart';
import '../services/report_exporter.dart';
import '../services/report_sharer.dart';
import '../services/session_manager.dart';

import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_image.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final Future<List<ScanReport>> _reportsFuture = _loadReports();
  final ApiService _apiService = ApiService();

  Future<List<ScanReport>> _loadReports() async {
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

    return combined;
  }


  @override
  Widget build(BuildContext context) {
    return _MedicalPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Scan History',
            subtitle: 'Review saved AI dental diagnostic reports.',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          FutureBuilder<List<ScanReport>>(
            future: _reportsFuture,
            builder: (context, snapshot) {
              final reports = snapshot.data ?? [];

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF69C7C3)),
                );
              }

              if (reports.isEmpty) {
                return GlassCard(
                  borderRadius: 30,
                  opacity: 0.14,
                  borderOpacity: 0.22,
                  glowColor: const Color(0xFF2B7A78),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.folder_open_outlined,
                        color: Color(0xFF69C7C3),
                        size: 44,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No reports available',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Save a scan report to build your medical archive.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: reports
                    .map(
                      (report) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _HistoryCard(
                          report: report,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ReportDetailScreen(report: report),
                              ),
                            );
                          },
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.report, required this.onTap});

  final ScanReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 30,
      opacity: 0.14,
      borderOpacity: 0.22,
      glowColor: const Color(0xFF2B7A78),
      onTap: onTap,
      child: Row(
        children: [
          _Thumbnail(report: report),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(report.date),
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plaque ${report.plaque}% - Score ${report.score} - Confidence ${(report.confidence * 100).round()}%',
                  style: TextStyle(
                    color: AppTheme.textSecondary(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _SeverityBadge(text: report.severity),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: AppTheme.textSecondary(context)),
        ],
      ),
    );
  }
}

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.report});

  final ScanReport report;

  Future<void> _downloadReport(BuildContext context) async {
    try {
      final path = await exportReportPdf(
        ReportExportData(
          scanDate: report.date,
          originalImage: report.imagePath,
          processedImage: report.processedImage,
          plaquePercent: report.plaque,
          oralHealthScore: report.score,
          riskLevel: report.severity,
          confidence: report.confidence,
          recommendation: report.recommendation,
        ),
      );

      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF3BA7A4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Text('PDF report saved: $path'),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFF87171),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Text('Unable to download report: $error'),
        ),
      );
    }
  }

  Future<void> _shareReport(BuildContext context) async {
    await ReportSharer.shareReportData(
      date: report.date,
      plaquePercent: report.plaque,
      severity: report.severity,
      score: report.score,
      confidence: report.confidence,
      recommendation: report.recommendation,
      localImagePath: report.imagePath,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _MedicalPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'Detailed Report',
            subtitle: 'Complete plaque diagnostic report.',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          _ReportImage(
            label: 'Original image',
            path: report.imagePath,
            report: report,
          ),
          const SizedBox(height: 14),
          _ReportImage(
            label: 'Processed image',
            path: report.processedImage,
            report: report,
          ),
          const SizedBox(height: 18),
          GlassCard(
            borderRadius: 30,
            opacity: 0.15,
            borderOpacity: 0.24,
            glowColor: const Color(0xFF2B7A78),
            child: Column(
              children: [
                _ReportDetailRow(
                  label: 'Scan date',
                  value: _formatDate(report.date),
                ),
                const SizedBox(height: 10),
                _ReportDetailRow(label: 'Plaque %', value: '${report.plaque}%'),
                const SizedBox(height: 10),
                _ReportDetailRow(
                  label: 'Oral Health Score',
                  value: '${report.score}',
                ),
                const SizedBox(height: 10),
                _ReportDetailRow(label: 'Risk Level', value: report.severity),
                const SizedBox(height: 10),
                _ReportDetailRow(
                  label: 'Confidence',
                  value: '${(report.confidence * 100).round()}%',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GlassCard(
            borderRadius: 30,
            opacity: 0.14,
            borderOpacity: 0.22,
            glowColor: const Color(0xFF3BA7A4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: Color(0xFF69C7C3), size: 20),
                    const SizedBox(width: 10),
                    Text(
                      'Suggestions for Betterment',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...report.suggestionsList.map(
                  (suggestion) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF3BA7A4),
                            size: 15,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            suggestion,
                            style: TextStyle(
                              color: AppTheme.textPrimary(context),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          GlassButton(
            label: 'Download Report',
            icon: Icons.download_rounded,
            isPrimary: true,
            onPressed: () => _downloadReport(context),
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Share Report',
            icon: Icons.share_rounded,
            onPressed: () => _shareReport(context),
          ),
        ],
      ),
    );
  }

}

class _ReportImage extends StatelessWidget {
  const _ReportImage({
    required this.label,
    required this.path,
    required this.report,
  });

  final String label;
  final String path;
  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final imageUrl = report.isBackend ? ApiService().mediaUrl(path) : path;

    return GlassCard(
      borderRadius: 30,
      padding: const EdgeInsets.all(12),
      opacity: 0.15,
      borderOpacity: 0.24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 210,
              width: double.infinity,
              color: Colors.white.withValues(alpha: 0.08),
              child: path.isNotEmpty && report.isBackend
                  ? buildNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
                  : path.isNotEmpty
                  ? buildPlatformImage(imagePath: imageUrl, fit: BoxFit.cover)
                  : const Icon(
                      Icons.image_not_supported_outlined,
                      color: Color(0xFF69C7C3),
                      size: 42,
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
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

class _ReportDetailRow extends StatelessWidget {
  const _ReportDetailRow({required this.label, required this.value});

  final String label;
  final String value;

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

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.report});

  final ScanReport report;

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    final path = report.processedImage.isNotEmpty
        ? report.processedImage
        : report.imagePath;
    final imageUrl = report.isBackend ? apiService.mediaUrl(path) : path;

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 58,
        height: 58,
        color: Colors.white.withValues(alpha: 0.08),
        child: imageUrl.isNotEmpty && report.isBackend
            ? buildNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover)
            : imageUrl.isNotEmpty
            ? buildPlatformImage(imagePath: imageUrl, fit: BoxFit.cover)
            : const Icon(
                Icons.document_scanner_outlined,
                color: Color(0xFF69C7C3),
              ),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(text);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

Color _severityColor(String severity) {
  switch (severity.toLowerCase()) {
    case 'low':
      return const Color(0xFF34D399);
    case 'high':
      return const Color(0xFFF87171);
    default:
      return const Color(0xFFFBBF24);
  }
}

String _formatDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

class _MedicalPage extends StatelessWidget {
  const _MedicalPage({required this.child});

  final Widget child;

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
            child: child,
          ),
        ),
      ),
    );
  }
}

class _BackHeader extends StatelessWidget {
  const _BackHeader({required this.title, required this.subtitle, this.onBack});

  final String title;
  final String subtitle;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2B7A78)),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.12),
            ),
          ),
        if (onBack != null) const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: AppTheme.textPrimary(context),
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            color: AppTheme.textSecondary(context),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
