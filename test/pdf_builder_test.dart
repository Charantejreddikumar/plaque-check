import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/services/report_exporter.dart';
import 'package:plaquecheck/services/report_pdf_builder.dart';

void main() {
  test('buildReportPdf generates valid PDF bytes', () {
    final report = ReportExportData(
      scanDate: DateTime.now(),
      originalImage: 'test_orig.jpg',
      processedImage: 'test_proc.jpg',
      plaquePercent: 15,
      oralHealthScore: 85,
      riskLevel: 'Low',
      confidence: 0.9,
      recommendation: 'Regular brushing',
    );

    final bytes = buildReportPdf(report);
    expect(bytes, isNotNull);
    expect(bytes.length, greaterThan(0));
  });
}
