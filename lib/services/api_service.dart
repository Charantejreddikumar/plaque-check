import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

import 'app_config.dart';
import 'plaque_prediction.dart';
import 'session_manager.dart';

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  String get _baseUrl => AppConfig.normalizeApiBaseUrl(
    (_baseUrlOverride ?? AppConfig.apiBaseUrl).trim(),
  );

  Future<Map<String, String>> _authHeaders() async {
    final user = await SessionManager.currentUser();
    if (user != null && user.accessToken.isNotEmpty) {
      return {'Authorization': 'Bearer ${user.accessToken}'};
    }
    return {};
  }

  Future<PlaquePrediction> predictPlaque(XFile image) async {
    try {
      debugPrint('========== PLAQUECHECK ==========');
      debugPrint('BASE URL: $_baseUrl');
      final url = Uri.parse('$_baseUrl/predict');
      debugPrint('PREDICT URL: $url');

      final bytes = await image.readAsBytes();
      final fileName = _fileNameFor(image);
      final mime = lookupMimeType(image.path)?.split('/');

      debugPrint('IMAGE SIZE: ${bytes.length} bytes');
      debugPrint('IMAGE PATH: ${image.path}');
      debugPrint('MIME: ${lookupMimeType(image.path)}');
      debugPrint('FILENAME: $fileName');

      final request = http.MultipartRequest('POST', url);
      final headers = await _authHeaders();
      request.headers.addAll(headers);

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName,
          contentType: MediaType(mime?[0] ?? 'image', mime?[1] ?? 'jpeg'),
        ),
      );

      debugPrint('Sending POST request...');

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 60));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RAW RESPONSE: ${response.body}');

      final body = _decodeBody(response.body);

      if (response.statusCode == 401) {
        await SessionManager.clearSession();
        throw const ApiException('Session expired. Please log in again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorMessage(body));
      }

      debugPrint('Prediction parsed successfully');

      return PlaquePrediction.fromJson(body);
    } catch (e, stack) {
      debugPrint('PREDICTION ERROR: $e');
      debugPrint(stack.toString());

      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(e.toString());
    }
  }

  Future<PlaquePrediction> predictPlaqueBatch(List<XFile> images) async {
    if (images.isEmpty) {
      throw const ApiException('Please select teeth images for analysis.');
    }
    if (images.length == 1) {
      return predictPlaque(images.first);
    }
    try {
      debugPrint('========== PLAQUECHECK BATCH (3-IMAGE AVG) ==========');
      debugPrint('BASE URL: $_baseUrl');
      final url = Uri.parse('$_baseUrl/predict/batch');
      debugPrint('PREDICT BATCH URL: $url');

      final request = http.MultipartRequest('POST', url);
      final headers = await _authHeaders();
      request.headers.addAll(headers);

      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final bytes = await image.readAsBytes();
        final fileName = _fileNameFor(image);
        final mime = lookupMimeType(image.path)?.split('/');

        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            bytes,
            filename: fileName,
            contentType: MediaType(mime?[0] ?? 'image', mime?[1] ?? 'jpeg'),
          ),
        );
      }

      debugPrint('Sending batch POST request with ${images.length} images...');

      final streamedResponse = await _client
          .send(request)
          .timeout(const Duration(seconds: 90));

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('BATCH STATUS CODE: ${response.statusCode}');
      debugPrint('RAW BATCH RESPONSE: ${response.body}');

      final body = _decodeBody(response.body);

      if (response.statusCode == 401) {
        await SessionManager.clearSession();
        throw const ApiException('Session expired. Please log in again.');
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(_errorMessage(body));
      }

      debugPrint('Batch prediction parsed successfully (3-image average plaque calculated)');

      return PlaquePrediction.fromJson(body);
    } catch (e, stack) {
      debugPrint('BATCH PREDICTION ERROR: $e');
      debugPrint(stack.toString());

      if (e is ApiException) {
        rethrow;
      }
      throw ApiException(e.toString());
    }
  }

  Future<bool> isBackendHealthy() async {
    try {
      debugPrint('Checking backend health...');
      final url = Uri.parse('$_baseUrl/health');
      debugPrint('HEALTH URL: $url');

      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 3));

      debugPrint('HEALTH STATUS: ${response.statusCode}');

      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('HEALTH ERROR: $e');
      return false;
    }
  }

  Future<List<ScanReport>> fetchReports() async {
    try {
      final url = Uri.parse('$_baseUrl/reports');
      debugPrint('REPORTS URL: $url');

      final headers = await _authHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 25));


      debugPrint('REPORTS RESPONSE STATUS: ${response.statusCode}');
      debugPrint('REPORTS RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await SessionManager.clearSession();
        throw const ApiException('Session expired. Please log in again.');
      }

      final decoded = jsonDecode(response.body);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (decoded is Map<String, dynamic>) {
          throw ApiException(_errorMessage(decoded));
        }

        throw const ApiException('Unable to load reports.');
      }

      if (decoded is! List) {
        throw const FormatException('Invalid reports response.');
      }

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(ScanReport.fromBackendJson)
          .toList();
    } catch (e) {
      debugPrint('REPORT ERROR: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> registerDoctor(Map<String, dynamic> doctorData) async {
    final url = Uri.parse('$_baseUrl/register/doctor');
    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(doctorData),
    );
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchDoctorDashboard() async {
    final url = Uri.parse('$_baseUrl/doctor/dashboard');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<List<dynamic>> searchPatients([String query = '']) async {
    final url = Uri.parse('$_baseUrl/doctor/patients?query=$query');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> fetchPendingReviews() async {
    final url = Uri.parse('$_baseUrl/doctor/reports/pending');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> fetchReportDetails(int reportId) async {
    final url = Uri.parse('$_baseUrl/doctor/reports/$reportId');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> reviewReport(int reportId, Map<String, dynamic> reviewData) async {
    final url = Uri.parse('$_baseUrl/doctor/reports/$reportId/review');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(url, headers: headers, body: jsonEncode(reviewData));
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchDoctorAnalytics() async {
    final url = Uri.parse('$_baseUrl/doctor/analytics');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchPatientDetail(int patientId) async {
    final url = Uri.parse('$_baseUrl/doctor/patients/$patientId');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<List<dynamic>> fetchDoctorNotifications() async {
    final url = Uri.parse('$_baseUrl/doctor/notifications');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> fetchAdminDashboard() async {
    final url = Uri.parse('$_baseUrl/admin/dashboard');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<List<dynamic>> fetchDoctorsList() async {
    final url = Uri.parse('$_baseUrl/admin/doctors');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<bool> approveDoctor(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/doctors/$userId/approve');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> deactivateDoctor(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/doctors/$userId/deactivate');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<List<dynamic>> fetchAuditLogs() async {
    final url = Uri.parse('$_baseUrl/admin/audit-logs');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<List<dynamic>> fetchAdminPatients({String query = '', String filterType = 'all'}) async {
    final url = Uri.parse('$_baseUrl/admin/patients?q=$query&filter_type=$filterType');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> fetchPatientDetails(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/patients/$userId');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<bool> updatePatientStatus(int userId, String status) async {
    final url = Uri.parse('$_baseUrl/admin/patients/$userId/status?status=$status');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> resetUserPassword(int userId, String newPassword) async {
    final url = Uri.parse('$_baseUrl/admin/patients/$userId/reset-password');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'new_password': newPassword}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> assignDoctorToPatient(int patientId, int doctorId) async {
    final url = Uri.parse('$_baseUrl/admin/patients/$patientId/assign-doctor');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'doctor_id': doctorId}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> rejectDoctor(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/doctors/$userId/reject');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> suspendDoctor(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/doctors/$userId/suspend');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> reactivateDoctor(int userId) async {
    final url = Uri.parse('$_baseUrl/admin/doctors/$userId/reactivate');
    final headers = await _authHeaders();
    final response = await _client.post(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<List<dynamic>> fetchAdminReports({String filterType = 'all', String query = ''}) async {
    final url = Uri.parse('$_baseUrl/admin/reports?filter_type=$filterType&q=$query');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<Map<String, dynamic>> fetchAiMonitoringStatus() async {
    final url = Uri.parse('$_baseUrl/admin/ai/status');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<bool> deployAiModel(String version) async {
    final url = Uri.parse('$_baseUrl/admin/ai/deploy');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'model_version': version}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<bool> rollbackAiModel(String version) async {
    final url = Uri.parse('$_baseUrl/admin/ai/rollback');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({'model_version': version}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<Map<String, dynamic>> fetchAdminAnalyticsData() async {
    final url = Uri.parse('$_baseUrl/admin/analytics');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<List<dynamic>> fetchAdminNotifications() async {
    final url = Uri.parse('$_baseUrl/admin/notifications');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : [];
  }

  Future<bool> sendBroadcastNotification({
    required String targetRole,
    required String title,
    required String message,
  }) async {
    final url = Uri.parse('$_baseUrl/admin/notifications/broadcast');
    final headers = await _authHeaders();
    headers['Content-Type'] = 'application/json';
    final response = await _client.post(
      url,
      headers: headers,
      body: jsonEncode({
        'target_role': targetRole,
        'title': title,
        'message': message,
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = _decodeBody(response.body);
      throw ApiException(_errorMessage(body));
    }
    return true;
  }

  Future<Map<String, dynamic>> fetchSystemHealth() async {
    final url = Uri.parse('$_baseUrl/admin/system-health');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchStorageStats() async {
    final url = Uri.parse('$_baseUrl/admin/storage');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> fetchAdminProfile() async {
    final url = Uri.parse('$_baseUrl/admin/profile');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<Map<String, dynamic>> globalAdminSearch(String query) async {
    final url = Uri.parse('$_baseUrl/admin/search?q=$query');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    final body = _decodeBody(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_errorMessage(body));
    }
    return body;
  }

  Future<String> exportAdminData(String resource) async {
    final url = Uri.parse('$_baseUrl/admin/export/$resource');
    final headers = await _authHeaders();
    final response = await _client.get(url, headers: headers);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw const ApiException('Failed to export dataset.');
    }
    return response.body;
  }

  String mediaUrl(String relativePath, {String? token}) {
    if (relativePath.isEmpty || relativePath.startsWith('http')) {
      return relativePath;
    }

    final baseUrl = '$_baseUrl/$relativePath';
    if (token != null && token.isNotEmpty) {
      final uri = Uri.parse(baseUrl);
      final params = Map<String, String>.from(uri.queryParameters);
      params['token'] = token;
      final url = uri.replace(queryParameters: params).toString();
      debugPrint('MEDIA URL: $url');
      return url;
    }

    debugPrint('MEDIA URL: $baseUrl');
    return baseUrl;
  }

  Map<String, dynamic> _decodeBody(String source) {
    try {
      final decoded = jsonDecode(source);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}

    return {};
  }

  String _errorMessage(Map<String, dynamic> body) {
    final detail = body['detail'];

    if (detail is String && detail.isNotEmpty) {
      return detail;
    }
    if (detail is List && detail.isNotEmpty) {
      return detail.map((e) => e.toString()).join('\n');
    }

    return 'Plaque analysis failed.';
  }

  String _fileNameFor(XFile image) {
    if (image.name.isNotEmpty) {
      return image.name;
    }

    final path = image.path.replaceAll('\\', '/');

    final name = path.split('/').last;

    return name.isEmpty ? 'plaquecheck-upload.jpg' : name;
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
