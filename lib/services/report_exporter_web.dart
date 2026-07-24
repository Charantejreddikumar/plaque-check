// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'report_exporter.dart';
import 'report_pdf_builder.dart';

Future<String> exportReportPdf(ReportExportData report) async {
  final fileName =
      'plaquecheck_report_${report.scanDate.millisecondsSinceEpoch}.pdf';
  final data = base64Encode(buildReportPdf(report));
  final anchor = html.AnchorElement(href: 'data:application/pdf;base64,$data')
    ..download = fileName
    ..style.display = 'none';

  html.document.body?.children.add(anchor);
  anchor.click();
  anchor.remove();

  return fileName;
}
