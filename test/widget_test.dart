import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/main.dart';
import 'package:plaquecheck/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('PlaqueCheck app starts at splash screen', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ThemeProviderScope(
        provider: ThemeProvider(ThemeMode.dark),
        child: const PlaqueCheckApp(),
      ),
    );

    expect(find.text('PlaqueCheck'), findsOneWidget);
    expect(find.text('Know Your Plaque. Own Your Health.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to PlaqueCheck'), findsOneWidget);
  });
}
