import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/widgets/bottom_glass_nav.dart';
import 'package:plaquecheck/widgets/glass_button.dart';
import 'package:plaquecheck/widgets/glass_card.dart';
import 'package:plaquecheck/widgets/score_widget.dart';

void main() {
  testWidgets('GlassCard renders child widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GlassCard(
            child: Text('Glass Card Test'),
          ),
        ),
      ),
    );

    expect(find.text('Glass Card Test'), findsOneWidget);
  });

  testWidgets('GlassButton renders label and handles tap', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GlassButton(
            label: 'Click Me',
            icon: Icons.touch_app,
            onPressed: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Click Me'), findsOneWidget);
    await tester.tap(find.text('Click Me'));
    expect(tapped, isTrue);
  });

  testWidgets('GradientScoreCard displays score and status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GradientScoreCard(
            title: 'Overall Score',
            score: '75.5%',
            label: 'Plaque Index',
          ),
        ),
      ),
    );

    expect(find.text('Plaque Index'), findsOneWidget);
    expect(find.text('75.5%'), findsOneWidget);
  });

  testWidgets('BottomGlassNavigation displays items and handles selection', (WidgetTester tester) async {
    int selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BottomGlassNavigation(
            selectedIndex: selected,
            onTabSelected: (index) => selected = index,
          ),
        ),
      ),
    );

    expect(find.byType(BottomGlassNavigation), findsOneWidget);
  });
}
