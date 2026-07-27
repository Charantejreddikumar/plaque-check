import 'dart:convert';

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/plaque_prediction.dart';
import '../services/report_exporter.dart';
import '../services/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/platform_image.dart';
import 'history_screen.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  Future<void> _saveReport(
    BuildContext context,
    AnalysisResultArguments result,
  ) async {
    final existing = await SessionManager.getReportsForCurrentUser();
    final reportData = {
      'imagePath': result.image.path,
      'processedImage': result.prediction.processedImage,
      'date': DateTime.now().toIso8601String(),
      'plaque': result.prediction.plaquePercent,
      'severity': result.prediction.severity,
      'score': result.prediction.oralHealthScore,
      'confidence': result.prediction.confidence,
      'recommendation': result.prediction.recommendation,
      'isDemo': false,
    };

    await SessionManager.saveReportsForCurrentUser([
      jsonEncode(reportData),
      ...existing,
    ]);

    final savedReport = ScanReport.fromLocalJson(reportData);

    if (!context.mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: const Color(0xFF2B7A78).withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3BA7A4).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_outline, color: Color(0xFF3BA7A4), size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Report Saved',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Plaque map, score & betterment tips preserved.',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            GlassButton(
              label: 'View Saved Report',
              icon: Icons.visibility_outlined,
              isPrimary: true,
              onPressed: () {
                Navigator.pop(bottomSheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => ReportDetailScreen(report: savedReport),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Export PDF Report',
              icon: Icons.picture_as_pdf_outlined,
              onPressed: () {
                Navigator.pop(bottomSheetContext);
                _exportPdf(context, result);
              },
            ),
            const SizedBox(height: 12),
            GlassButton(
              label: 'Close',
              icon: Icons.close,
              onPressed: () => Navigator.pop(bottomSheetContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPdf(
    BuildContext context,
    AnalysisResultArguments result,
  ) async {
    try {
      final path = await exportReportPdf(
        ReportExportData(
          scanDate: DateTime.now(),
          originalImage: result.image.path,
          processedImage: result.prediction.processedImage,
          plaquePercent: result.prediction.plaquePercent,
          oralHealthScore: result.prediction.oralHealthScore,
          riskLevel: result.prediction.severity,
          confidence: result.prediction.confidence,
          recommendation: result.prediction.recommendation,
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
          content: Text('Unable to export PDF: $error'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)?.settings.arguments as AnalysisResultArguments?;

    if (result == null) {
      return _MedicalPage(
        child: _BackHeader(
          title: 'AI Clinical Report',
          subtitle: 'No backend analysis result was received.',
          onBack: () => Navigator.pop(context),
        ),
      );
    }

    final prediction = result.prediction;
    final apiService = ApiService();

    return _MedicalPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackHeader(
            title: 'AI Clinical Report',
            subtitle: 'Backend-generated plaque analysis result',
            onBack: () => Navigator.pop(context),
          ),
          const SizedBox(height: 24),
          _ResultImagePreview(
            label: 'Original scan',
            imagePath: result.image.path,
            fallbackUrl: apiService.mediaUrl(prediction.imagePath),
          ),
          if (prediction.processedImage.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ResultImagePreview(
              label: 'AI plaque map',
              imagePath: prediction.processedImage,
              processedUrl: apiService.mediaUrl(prediction.processedImage),
              isNetworkImage: true,
            ),
          ],
          const SizedBox(height: 18),
          _ReportHeroCard(
            plaquePercentage: prediction.plaquePercent,
            severity: prediction.severity,
            oralHealthScore: prediction.oralHealthScore,
          ),
          const SizedBox(height: 18),
          _BettermentSuggestionsCard(
            suggestions: prediction.suggestionsList,
          ),
          const SizedBox(height: 18),
          _ClinicalSummaryCard(
            confidence: prediction.confidence,
            recommendation: prediction.recommendation,
          ),
          const SizedBox(height: 24),
          GlassButton(
            label: 'Save Report',
            icon: Icons.save_alt,
            isPrimary: true,
            onPressed: () => _saveReport(context, result),
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Export PDF',
            icon: Icons.picture_as_pdf_outlined,
            onPressed: () => _exportPdf(context, result),
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Share',
            icon: Icons.ios_share_outlined,
            onPressed: () => _showPlaceholder(context, 'Report sharing'),
          ),
          const SizedBox(height: 12),
          GlassButton(
            label: 'Scan Again',
            icon: Icons.camera_alt_outlined,
            onPressed: () =>
                Navigator.pushReplacementNamed(context, '/scan-instructions'),
          ),
        ],
      ),
    );
  }

  void _showPlaceholder(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF3BA7A4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        content: Text(
          '$feature will be connected with backend services later.',
        ),
      ),
    );
  }
}

class _ResultImagePreview extends StatelessWidget {
  const _ResultImagePreview({
    required this.label,
    required this.imagePath,
    this.processedUrl = '',
    this.fallbackUrl = '',
    this.isNetworkImage = false,
  });

  final String label;
  final String imagePath;
  final String processedUrl;
  final String fallbackUrl;
  final bool isNetworkImage;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 32,
      opacity: 0.16,
      borderOpacity: 0.24,
      glowColor: const Color(0xFF2B7A78),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          height: 210,
          width: double.infinity,
          alignment: Alignment.center,
          color: Colors.white.withValues(alpha: 0.06),
          child: imagePath.isEmpty && processedUrl.isEmpty && fallbackUrl.isEmpty
              ? const _HeatmapPlaceholder()
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isNetworkImage)
                      buildNetworkImage(
                        imageUrl: processedUrl,
                        fit: BoxFit.cover,
                      )
                    else
                      buildPlatformImage(
                        imagePath: imagePath,
                        fit: BoxFit.cover,
                        errorWidget: fallbackUrl.isNotEmpty
                            ? buildNetworkImage(
                                imageUrl: fallbackUrl,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xFF0F172A).withValues(alpha: 0.34),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 14,
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeatmapPlaceholder extends StatelessWidget {
  const _HeatmapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                const Color(0xFF2B7A78).withValues(alpha: 0.42),
                const Color(0xFF3BA7A4).withValues(alpha: 0.08),
                Colors.transparent,
              ],
            ),
          ),
        ),
        Positioned(
          top: 52,
          child: Icon(
            Icons.blur_on,
            color: const Color(0xFF69C7C3).withValues(alpha: 0.9),
            size: 70,
          ),
        ),
        const Positioned(
          bottom: 34,
          child: Text(
            'Clinical Heatmap Placeholder',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportHeroCard extends StatelessWidget {
  const _ReportHeroCard({
    required this.plaquePercentage,
    required this.severity,
    required this.oralHealthScore,
  });

  final int plaquePercentage;
  final String severity;
  final int oralHealthScore;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 34,
      opacity: 0.16,
      borderOpacity: 0.24,
      glowColor: const Color(0xFF2B7A78),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Plaque Analysis Report',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _CircularScore(
                score: oralHealthScore,
                progress: oralHealthScore / 100,
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plaque Percentage',
                      style: TextStyle(
                        color: AppTheme.textSecondary(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$plaquePercentage%',
                      style: TextStyle(
                        color: AppTheme.textPrimary(context),
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _SeverityBadge(label: severity),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircularScore extends StatelessWidget {
  const _CircularScore({required this.score, required this.progress});

  final int score;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 112,
          height: 112,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2B7A78).withValues(alpha: 0.26),
                blurRadius: 34,
              ),
            ],
          ),
        ),
        SizedBox(
          width: 104,
          height: 104,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 9,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69C7C3)),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: TextStyle(
                color: AppTheme.textPrimary(context),
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'ORAL SCORE',
              style: TextStyle(
                color: AppTheme.textSecondary(context),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BettermentSuggestionsCard extends StatelessWidget {
  const _BettermentSuggestionsCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 30,
      opacity: 0.14,
      borderOpacity: 0.22,
      glowColor: const Color(0xFF3BA7A4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Suggestions for Betterment',
                  style: TextStyle(
                    color: AppTheme.textPrimary(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...suggestions.map(
            (suggestion) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: Color(0xFF3BA7A4),
                      size: 16,
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
    );
  }
}

class _ClinicalSummaryCard extends StatelessWidget {
  const _ClinicalSummaryCard({
    required this.confidence,
    required this.recommendation,
  });

  final double confidence;
  final String recommendation;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 30,
      opacity: 0.14,
      borderOpacity: 0.22,
      glowColor: const Color(0xFF3BA7A4),
      child: Column(
        children: [
          _MetricRow(
            icon: Icons.warning_amber_rounded,
            label: 'Confidence',
            value: '${(confidence * 100).round()}% analysis confidence',
          ),
          const SizedBox(height: 16),
          _MetricRow(
            icon: Icons.medical_information_outlined,
            label: 'Recommendation',
            value: recommendation,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF69C7C3), Color(0xFF3BA7A4)],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: Colors.white, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimary(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.1)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
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
