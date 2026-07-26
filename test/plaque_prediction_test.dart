import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/services/plaque_prediction.dart';

void main() {
  group('PlaquePrediction Model Tests', () {
    test('PlaquePrediction.fromJson parses backend payload correctly', () {
      final json = {
        'report_id': 100,
        'timestamp': '2026-07-26T12:00:00Z',
        'plaque_percent': 34,
        'severity': 'Moderate',
        'confidence': 0.85,
        'image_path': 'uploads/1/abc.jpg',
        'processed_image': 'processed/1/abc.png',
        'recommendation': 'Brush twice daily and floss.',
      };

      final prediction = PlaquePrediction.fromJson(json);

      expect(prediction.reportId, 100);
      expect(prediction.plaquePercent, 34);
      expect(prediction.severity, 'Moderate');
      expect(prediction.confidence, 0.85);
      expect(prediction.oralHealthScore, 66);
    });

    test('ScanReport.fromBackendJson conversion', () {
      final json = {
        'report_id': 200,
        'timestamp': '2026-07-26T12:00:00Z',
        'plaque_percent': 5,
        'severity': 'Healthy',
        'confidence': 0.95,
        'image_path': 'img.jpg',
        'processed_image': 'img_proc.png',
        'recommendation': 'Keep up the good work.',
      };

      final report = ScanReport.fromBackendJson(json);
      expect(report.plaque, 5);
      expect(report.severity, 'Healthy');
      expect(report.score, 95);
      expect(report.confidence, 0.95);
      expect(report.isBackend, true);
    });
  });
}
