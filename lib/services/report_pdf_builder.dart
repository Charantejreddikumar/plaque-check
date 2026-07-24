import 'dart:convert';
import 'dart:typed_data';

import 'report_exporter.dart';

Uint8List buildReportPdf(ReportExportData report) {
  final buffer = BytesBuilder();
  final offsets = <int>[];

  void write(String value) {
    buffer.add(ascii.encode(value));
  }

  void object(int id, String body) {
    offsets.add(buffer.length);
    write('$id 0 obj\n$body\nendobj\n');
  }

  final lines = [
    'PlaqueCheck Diagnostic Report',
    'Scan date: ${_formatDate(report.scanDate)}',
    'Plaque percentage: ${report.plaquePercent}%',
    'Oral Health Score: ${report.oralHealthScore}',
    'Risk Level: ${report.riskLevel}',
    'Confidence: ${(report.confidence * 100).round()}%',
    'Original image: ${report.originalImage.isEmpty ? 'Not available' : report.originalImage}',
    'Processed image: ${report.processedImage.isEmpty ? 'Not available' : report.processedImage}',
    'Recommendations:',
    report.recommendation.isEmpty
        ? 'No recommendation available.'
        : report.recommendation,
  ];

  final content = StringBuffer('BT\n/F1 18 Tf\n72 760 Td\n');
  for (var i = 0; i < lines.length; i++) {
    if (i == 1) {
      content.write('/F1 11 Tf\n');
    }
    content.write('(${_pdfText(lines[i])}) Tj\n');
    content.write('0 -24 Td\n');
  }
  content.write('ET');
  final stream = content.toString();

  write('%PDF-1.4\n');
  object(1, '<< /Type /Catalog /Pages 2 0 R >>');
  object(2, '<< /Type /Pages /Kids [3 0 R] /Count 1 >>');
  object(
    3,
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] '
    '/Resources << /Font << /F1 5 0 R >> >> /Contents 4 0 R >>',
  );
  object(
    4,
    '<< /Length ${ascii.encode(stream).length} >>\nstream\n$stream\nendstream',
  );
  object(5, '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>');

  final xrefOffset = buffer.length;
  write('xref\n0 6\n0000000000 65535 f \n');
  for (final offset in offsets) {
    write('${offset.toString().padLeft(10, '0')} 00000 n \n');
  }
  write('trailer\n<< /Size 6 /Root 1 0 R >>\nstartxref\n$xrefOffset\n%%EOF\n');

  return buffer.toBytes();
}

String _pdfText(String value) {
  return value
      .replaceAll('\\', r'\\')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)')
      .replaceAll('\n', ' ');
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
