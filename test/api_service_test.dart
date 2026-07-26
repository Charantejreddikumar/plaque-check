import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plaquecheck/services/api_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockClient extends http.BaseClient {
  MockClient(this._handler);
  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final res = await _handler(request);
    return http.StreamedResponse(
      Stream.value(res.bodyBytes),
      res.statusCode,
      headers: res.headers,
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ApiService Tests', () {
    test('isBackendHealthy returns true on 200', () async {
      final client = MockClient((req) async {
        return http.Response('{"status": "backend healthy"}', 200);
      });
      final apiService = ApiService(client: client, baseUrl: 'http://localhost:8000');
      expect(await apiService.isBackendHealthy(), isTrue);
    });

    test('isBackendHealthy returns false on 500 or error', () async {
      final client = MockClient((req) async {
        return http.Response('{"detail": "Internal server error"}', 500);
      });
      final apiService = ApiService(client: client, baseUrl: 'http://localhost:8000');
      expect(await apiService.isBackendHealthy(), isFalse);
    });

    test('fetchReports parses report list successfully', () async {
      final client = MockClient((req) async {
        return http.Response(
          '[{"report_id":1,"timestamp":"2026-07-26T12:00:00Z","plaque_percent":12,"severity":"Low","confidence":0.88,"image_path":"img1.jpg","processed_image":"img1_proc.jpg"}]',
          200,
        );
      });
      final apiService = ApiService(client: client, baseUrl: 'http://localhost:8000');
      final reports = await apiService.fetchReports();
      expect(reports.length, 1);
      expect(reports.first.plaque, 12);
      expect(reports.first.severity, 'Low');
    });

    test('mediaUrl formats relative and absolute URLs correctly', () {
      final apiService = ApiService(baseUrl: 'http://localhost:8000');
      expect(apiService.mediaUrl('http://example.com/pic.jpg'), 'http://example.com/pic.jpg');
      expect(apiService.mediaUrl('uploads/1/test.jpg'), 'http://localhost:8000/uploads/1/test.jpg');
      expect(apiService.mediaUrl(''), '');
    });
  });
}
