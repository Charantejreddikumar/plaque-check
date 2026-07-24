import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plaquecheck/services/api_service.dart';
import 'package:plaquecheck/services/app_config.dart';
import 'package:plaquecheck/services/auth_service.dart';
import 'package:plaquecheck/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    AppConfig.resetForTesting();
  });

  group('AppConfig', () {
    test('uses a single default API base URL', () {
      expect(AppConfig.defaultApiBaseUrl, 'http://192.168.1.13:8000');
      expect(AppConfig.apiBaseUrl, AppConfig.defaultApiBaseUrl);
    });

    test('normalizes configured API base URLs', () {
      final dirtyUrl = ' http://${String.fromCharCode(32)}192.168.1.13:8000/ ';

      expect(
        AppConfig.normalizeApiBaseUrl(dirtyUrl),
        'http://192.168.1.13:8000',
      );
    });

    test('rejects backend URLs without http or https scheme', () {
      expect(
        () => AppConfig.normalizeApiBaseUrl('192.168.1.13:8000'),
        throwsFormatException,
      );
    });

    test('loads saved API base URL from SharedPreferences', () async {
      final dirtyUrl = ' http://${String.fromCharCode(32)}192.168.1.13:8000/ ';
      SharedPreferences.setMockInitialValues({
        AppConfig.backendUrlPreferenceKey: dirtyUrl,
      });

      await AppConfig.loadSavedApiBaseUrl();

      expect(AppConfig.apiBaseUrl, 'http://192.168.1.13:8000');
    });

    test('builds development API base URL from host and port', () {
      expect(
        AppConfig.buildHttpApiBaseUrl(
          host: 'http://10.12.144.133',
          port: '8000',
        ),
        'http://10.12.144.133:8000',
      );
    });
  });

  group('services', () {
    test('ApiService uses shared default API base URL', () async {
      final client = _CapturingClient(
        response: http.Response('{"status":"backend healthy"}', 200),
      );
      final service = ApiService(client: client);

      final healthy = await service.isBackendHealthy();

      expect(healthy, isTrue);
      expect(
        client.lastRequest?.url.toString(),
        '${AppConfig.apiBaseUrl}/health',
      );
    });

    test(
      'ApiService resolves saved API base URL when request is made',
      () async {
        final dirtyUrl =
            ' http://${String.fromCharCode(32)}192.168.1.13:8000/ ';
        SharedPreferences.setMockInitialValues({});
        final client = _CapturingClient(
          response: http.Response('{"status":"backend healthy"}', 200),
        );
        final service = ApiService(client: client);

        await AppConfig.saveApiBaseUrl(dirtyUrl);

        final healthy = await service.isBackendHealthy();

        expect(healthy, isTrue);
        expect(
          client.lastRequest?.url.toString(),
          'http://192.168.1.13:8000/health',
        );
      },
    );

    test('AuthService uses shared default API base URL', () async {
      final client = _CapturingClient(
        response: http.Response(
          '{"success":true,"message":"Account created"}',
          200,
        ),
      );
      final service = AuthService(client: client);

      await service.register(
        name: 'Ada',
        email: 'ADA@EXAMPLE.COM',
        password: 'secret123',
      );

      expect(
        client.lastRequest?.url.toString(),
        '${AppConfig.apiBaseUrl}/register',
      );
      expect(client.lastRequestBody, contains('"email":"ada@example.com"'));
    });

    test(
      'AuthService login serializes JSON and session storage reloads user',
      () async {
        SharedPreferences.setMockInitialValues({});
        final client = _CapturingClient(
          response: http.Response(
            '{"success":true,"user_id":42,"name":"Ada Lovelace","email":"ada@example.com"}',
            200,
          ),
        );
        final service = AuthService(client: client);

        final user = await service.login(
          email: 'ADA@EXAMPLE.COM',
          password: 'secret123',
        );
        await SessionManager.saveSession(user);
        final savedUser = await SessionManager.currentUser();

        expect(
          client.lastRequest?.url.toString(),
          '${AppConfig.apiBaseUrl}/login',
        );
        expect(client.lastRequestBody, contains('"email":"ada@example.com"'));
        expect(client.lastRequestBody, contains('"password":"secret123"'));
        expect(user.userId, 42);
        expect(user.fullName, 'Ada Lovelace');
        expect(user.email, 'ada@example.com');
        expect(savedUser?.userId, 42);
        expect(savedUser?.fullName, 'Ada Lovelace');
        expect(savedUser?.email, 'ada@example.com');
      },
    );
  });
}

class _CapturingClient extends http.BaseClient {
  _CapturingClient({required this.response});

  final http.Response response;
  http.BaseRequest? lastRequest;
  String? lastRequestBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    lastRequest = request;

    if (request is http.Request) {
      lastRequestBody = request.body;
    }

    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
