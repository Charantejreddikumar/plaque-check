import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'app_config.dart';
import 'session_manager.dart';

class AuthService {
  AuthService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrlOverride = baseUrl;

  final http.Client _client;
  final String? _baseUrlOverride;

  String get _baseUrl => AppConfig.normalizeApiBaseUrl(
    (_baseUrlOverride ?? AppConfig.apiBaseUrl).trim(),
  );

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/register');
    debugPrint('REGISTER URL: $url');

    final response = await _client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      }),
    );

    debugPrint('REGISTER RESPONSE ${response.statusCode}: ${response.body}');

    final body = _decodeBody(response.body, context: 'REGISTER');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_errorMessage(body, 'Registration failed.'));
    }
  }

  Future<SessionUser> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/login');
    final payload = {'email': email.trim().toLowerCase(), 'password': password};
    final redactedPayload = {...payload, 'password': '<redacted>'};

    debugPrint('LOGIN URL: $url');
    debugPrint('LOGIN REQUEST BODY: ${jsonEncode(redactedPayload)}');

    late final http.Response response;
    try {
      response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (error, stack) {
      debugPrint('LOGIN EXCEPTION: $error');
      debugPrint(stack.toString());
      rethrow;
    }

    debugPrint('LOGIN STATUS CODE: ${response.statusCode}');
    debugPrint('LOGIN RESPONSE BODY: ${response.body}');

    final body = _decodeBody(response.body, context: 'LOGIN');
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_errorMessage(body, 'Invalid credentials'));
    }

    return SessionUser.fromLoginJson(body);
  }

  Map<String, dynamic> _decodeBody(String source, {required String context}) {
    try {
      final decoded = jsonDecode(source);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      debugPrint('$context JSON DECODE ERROR: expected object response');
    } catch (error, stack) {
      debugPrint('$context JSON DECODE ERROR: $error');
      debugPrint(stack.toString());
      // Fall through to a generic error payload.
    }
    return const {};
  }

  String _errorMessage(Map<String, dynamic> body, String fallback) {
    final detail = body['detail'];
    return detail is String && detail.isNotEmpty ? detail : fallback;
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
