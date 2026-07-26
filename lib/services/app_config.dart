import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  const AppConfig._();

  static const apiBaseUrlEnvironmentKey = 'PLAQUECHECK_API_BASE_URL';
  static const defaultApiBaseUrl = 'https://plaque-check-backend.onrender.com';
  static const backendUrlPreferenceKey = 'developer_backend_url';

  static String? _savedApiBaseUrl;

  static String get apiBaseUrl {
    if (_savedApiBaseUrl != null) {
      return normalizeApiBaseUrl(_savedApiBaseUrl!);
    }

    const configured = String.fromEnvironment(apiBaseUrlEnvironmentKey);

    if (configured.isNotEmpty) {
      return normalizeApiBaseUrl(configured);
    }

    return normalizeApiBaseUrl(defaultApiBaseUrl);
  }

  static Future<void> loadSavedApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(backendUrlPreferenceKey);
    _savedApiBaseUrl = _normalizeSavedApiBaseUrl(saved);
  }

  static Future<void> saveApiBaseUrl(String baseUrl) async {
    final normalized = normalizeApiBaseUrl(baseUrl);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(backendUrlPreferenceKey, normalized);
    _savedApiBaseUrl = normalized;
  }

  static Future<void> clearSavedApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(backendUrlPreferenceKey);
    _savedApiBaseUrl = null;
  }

  static String normalizeApiBaseUrl(String baseUrl) {
    var normalized = baseUrl.trim();
    normalized = normalized.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'/+$'), '');

    if (!_hasValidScheme(normalized)) {
      throw FormatException(
        'Backend URL must start with http:// or https://',
        baseUrl,
      );
    }

    return normalized;
  }

  static String buildHttpApiBaseUrl({
    required String host,
    required String port,
  }) {
    final normalizedHost = host
        .trim()
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .trim();
    final normalizedPort = port.trim();

    return normalizeApiBaseUrl('http://$normalizedHost:$normalizedPort');
  }

  static String? _normalizeSavedApiBaseUrl(String? saved) {
    if (saved == null || saved.trim().isEmpty) {
      return null;
    }

    try {
      return normalizeApiBaseUrl(saved);
    } on FormatException {
      return null;
    }
  }

  static bool _hasValidScheme(String url) {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  @visibleForTesting
  static void resetForTesting() {
    _savedApiBaseUrl = null;
  }
}
