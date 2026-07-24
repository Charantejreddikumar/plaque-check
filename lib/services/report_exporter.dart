import 'report_exporter_stub.dart'
    if (dart.library.io) 'report_exporter_io.dart'
    if (dart.library.html) 'report_exporter_web.dart'
    as report_exporter;

class ReportExportData {
  const ReportExportData({
    required this.scanDate,
    required this.originalImage,
    required this.processedImage,
    required this.plaquePercent,
    required this.oralHealthScore,
    required this.riskLevel,
    required this.confidence,
    required this.recommendation,
  });

  final DateTime scanDate;
  final String originalImage;
  final String processedImage;
  final int plaquePercent;
  final int oralHealthScore;
  final String riskLevel;
  final double confidence;
  final String recommendation;
}

Future<String> exportReportPdf(ReportExportData report) {
  return report_exporter.exportReportPdf(report);
}
