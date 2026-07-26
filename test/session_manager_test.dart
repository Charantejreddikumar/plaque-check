import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/services/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionManager Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('currentUser returns null when no session saved', () async {
      final user = await SessionManager.currentUser();
      expect(user, isNull);
    });

    test('saveSession and currentUser flow', () async {
      const user = SessionUser(
        userId: 10,
        fullName: 'Jane Smith',
        email: 'jane@example.com',
        accessToken: 'jwt_secret_token',
      );

      await SessionManager.saveSession(user);
      final retrieved = await SessionManager.currentUser();

      expect(retrieved, isNotNull);
      expect(retrieved?.userId, 10);
      expect(retrieved?.fullName, 'Jane Smith');
      expect(retrieved?.email, 'jane@example.com');
      expect(retrieved?.accessToken, 'jwt_secret_token');
    });

    test('clearSession clears session data', () async {
      const user = SessionUser(
        userId: 10,
        fullName: 'Jane Smith',
        email: 'jane@example.com',
      );
      await SessionManager.saveSession(user);
      await SessionManager.clearSession();

      final retrieved = await SessionManager.currentUser();
      expect(retrieved, isNull);
    });

    test('currentUserReportsKey returns formatted key', () async {
      expect(await SessionManager.currentUserReportsKey(), isNull);

      const user = SessionUser(userId: 42, fullName: 'Bob', email: 'bob@example.com');
      await SessionManager.saveSession(user);

      expect(await SessionManager.currentUserReportsKey(), 'scan_reports_user_42');
    });
  });
}
