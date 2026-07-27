import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'report_exporter.dart';
import 'report_pdf_builder.dart';

Future<String> exportReportPdf(ReportExportData report) async {
  final bytes = buildReportPdf(report);
  final fileName =
      'plaquecheck_report_${report.scanDate.millisecondsSinceEpoch}.pdf';

  Directory targetDir;
  try {
    final androidDownloadDir = Directory('/storage/emulated/0/Download');
    if (Platform.isAndroid && await androidDownloadDir.exists()) {
      targetDir = androidDownloadDir;
    } else {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        targetDir = downloadsDir;
      } else {
        final docsDir = await getApplicationDocumentsDirectory();
        targetDir = docsDir;
      }
    }
  } catch (_) {
    targetDir = Directory.systemTemp;
  }

  final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
