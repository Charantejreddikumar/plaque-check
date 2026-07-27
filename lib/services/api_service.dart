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
        await SessionManager.clearAllUserData();
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
          .timeout(const Duration(seconds: 5));

      debugPrint('REPORTS RESPONSE STATUS: ${response.statusCode}');
      debugPrint('REPORTS RESPONSE: ${response.body}');

      if (response.statusCode == 401) {
        await SessionManager.clearAllUserData();
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
