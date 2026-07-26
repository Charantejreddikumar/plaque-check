import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:plaquecheck/services/auth_service.dart';
import 'package:plaquecheck/services/session_manager.dart';

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

  group('AuthService Tests', () {
    test('Register success completes without exception', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/register');
        return http.Response('{"success": true, "message": "Account created"}', 200);
      });

      final authService = AuthService(client: client);
      await expectLater(
        authService.register(
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
        ),
        completes,
      );
    });

    test('Register error response handling throws AuthException', () async {
      final client = MockClient((req) async {
        return http.Response('{"detail": "Email already registered"}', 400);
      });

      final authService = AuthService(client: client);
      expect(
        () async => await authService.register(
          name: 'Test User',
          email: 'test@example.com',
          password: 'password123',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('Login success returns SessionUser', () async {
      final client = MockClient((req) async {
        expect(req.url.path, '/login');
        return http.Response(
          '{"success": true, "user_id": 1, "name": "John Doe", "email": "john@example.com", "access_token": "token123"}',
          200,
        );
      });

      final authService = AuthService(client: client);
      final user = await authService.login(
        email: 'john@example.com',
        password: 'password123',
      );
      expect(user.userId, 1);
      expect(user.fullName, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.accessToken, 'token123');
    });

    test('Login invalid credentials throws AuthException', () async {
      final client = MockClient((req) async {
        return http.Response('{"detail": "Invalid credentials"}', 401);
      });

      final authService = AuthService(client: client);
      expect(
        () async => await authService.login(
          email: 'wrong@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('SessionUser initials computation', () {
      const user1 = SessionUser(userId: 1, fullName: 'John Doe', email: 'j@e.com');
      expect(user1.initials, 'JD');

      const user2 = SessionUser(userId: 2, fullName: 'Alice', email: 'a@e.com');
      expect(user2.initials, 'AL');

      const user3 = SessionUser(userId: 3, fullName: '', email: 'e@e.com');
      expect(user3.initials, 'PC');
    });
  });
}
