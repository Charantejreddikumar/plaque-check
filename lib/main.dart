import 'package:flutter/material.dart';

import 'screens/admin_dashboard_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/comparison_screen.dart';
import 'screens/crop_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/developer_settings_screen.dart';
import 'screens/doctor_dashboard_screen.dart';
import 'screens/doctor_register_screen.dart';
import 'screens/doctor_review_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/history_screen.dart';
import 'screens/login_screen.dart';
import 'screens/preview_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/result_screen.dart';
import 'screens/scan_instruction_screen.dart';
import 'screens/scan_reminders_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/support_screen.dart';
import 'services/app_config.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadSavedApiBaseUrl();
  final themeProvider = await ThemeProvider.load();
  runApp(
    ThemeProviderScope(provider: themeProvider, child: const PlaqueCheckApp()),
  );
}

class PlaqueCheckApp extends StatelessWidget {
  const PlaqueCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = ThemeProviderScope.of(context);

    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          title: 'PlaqueCheck',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          initialRoute: '/splash',
          routes: {
            '/splash': (_) => const SplashScreen(),
            '/login': (_) => const LoginScreen(),
            '/register': (_) => const RegisterScreen(),
            '/register-doctor': (_) => const DoctorRegisterScreen(),
            '/forgot-password': (_) => const ForgotPasswordScreen(),
            '/dashboard': (_) => const DashboardScreen(),
            '/doctor-dashboard': (_) => const DoctorDashboardScreen(),
            '/doctor-review': (_) => const DoctorReviewScreen(),
            '/admin-dashboard': (_) => const AdminDashboardScreen(),
            '/scan-instructions': (_) => const ScanInstructionScreen(),
            '/scan': (_) => const ScanScreen(),
            '/crop': (_) => const CropScreen(),
            '/preview': (_) => const PreviewScreen(),
            '/analysis': (_) => const AnalysisScreen(),
            '/result': (_) => const ResultScreen(),
            '/history': (_) => const HistoryScreen(),
            '/saved-reports': (_) => const HistoryScreen(),
            '/comparison': (_) => const ComparisonScreen(),
            '/profile': (_) => const ProfileScreen(),
            '/settings': (_) => const SettingsScreen(),
            '/developer-settings': (_) => const DeveloperSettingsScreen(),
            '/privacy': (_) => const PrivacyScreen(),
            '/scan-reminders': (_) => const ScanRemindersScreen(),
            '/support': (_) => const SupportScreen(),
          },
          onGenerateRoute: (settings) {
            return PageRouteBuilder<void>(
              settings: settings,
              pageBuilder: (_, _, _) => const DashboardScreen(),
              transitionsBuilder: (_, animation, _, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            );
          },
        );
      },
    );
  }
}
