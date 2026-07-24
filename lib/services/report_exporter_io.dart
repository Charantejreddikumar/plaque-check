import 'dart:io';

import 'report_exporter.dart';
import 'report_pdf_builder.dart';

Future<String> exportReportPdf(ReportExportData report) async {
  final bytes = buildReportPdf(report);
  final fileName =
      'plaquecheck_report_${report.scanDate.millisecondsSinceEpoch}.pdf';
  final file = File(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$fileName',
  );
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
