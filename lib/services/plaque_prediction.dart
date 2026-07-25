import 'package:image_picker/image_picker.dart';

class PlaquePrediction {
  const PlaquePrediction({
    required this.imagePath,
    required this.processedImage,
    required this.plaquePercent,
    required this.severity,
    required this.confidence,
    required this.recommendation,
    required this.reportId,
    required this.timestamp,
  });

  factory PlaquePrediction.fromJson(
    Map<String, dynamic> json,
  ) {
    return PlaquePrediction(
      imagePath: json['image_path'] as String? ?? '',
      processedImage: json['processed_image'] as String? ?? '',
      plaquePercent: (json['plaque_percent'] as num?)?.round() ?? 0,
      severity: json['severity'] as String? ?? 'Unknown',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      recommendation: json['recommendation'] as String? ?? '',
      reportId: json['report_id'] as int? ?? 0,
      timestamp:
          DateTime.tryParse(
            json['timestamp'] as String? ?? '',
          ) ??
          DateTime.now(),
    );
  }

  final String imagePath;
  final String processedImage;
  final int plaquePercent;
  final String severity;
  final double confidence;
  final String recommendation;
  final int reportId;
  final DateTime timestamp;

  int get oralHealthScore =>
      (100 - plaquePercent).clamp(0, 100);
}

class ScanReport {
  const ScanReport({
    required this.imagePath,
    required this.processedImage,
    required this.date,
    required this.plaque,
    required this.severity,
    required this.score,
    required this.confidence,
    required this.recommendation,
    required this.isBackend,
  });

  factory ScanReport.fromBackendJson(
    Map<String, dynamic> json,
  ) {
    final plaque =
        (json['plaque_percent'] as num?)?.round() ?? 0;

    return ScanReport(
      imagePath: json['image_path'] as String? ?? '',
      processedImage:
          json['processed_image'] as String? ?? '',
      date:
          DateTime.tryParse(
            json['timestamp'] as String? ?? '',
          ) ??
          DateTime.now(),
      plaque: plaque,
      severity:
          json['severity'] as String? ?? 'Moderate',
      score: (100 - plaque).clamp(0, 100),
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0,
      recommendation:
          json['recommendation'] as String? ?? '',
      isBackend: true,
    );
  }

  factory ScanReport.fromLocalJson(
    Map<String, dynamic> json,
  ) {
    return ScanReport(
      imagePath: json['imagePath'] as String? ?? '',
      processedImage:
          json['processedImage'] as String? ?? '',
      date:
          DateTime.tryParse(
            json['date'] as String? ?? '',
          ) ??
          DateTime.now(),
      plaque: json['plaque'] as int? ?? 0,
      severity:
          json['severity'] as String? ?? 'Moderate',
      score: json['score'] as int? ?? 0,
      confidence:
          (json['confidence'] as num?)?.toDouble() ?? 0,
      recommendation:
          json['recommendation'] as String? ?? '',
      isBackend: false,
    );
  }

  final String imagePath;
  final String processedImage;
  final DateTime date;
  final int plaque;
  final String severity;
  final int score;
  final double confidence;
  final String recommendation;
  final bool isBackend;
}

class AnalysisResultArguments {
  const AnalysisResultArguments({
    required this.image,
    required this.prediction,
  });

  final XFile image;
  final PlaquePrediction prediction;
}