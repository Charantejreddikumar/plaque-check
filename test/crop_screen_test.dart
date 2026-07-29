import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:plaquecheck/screens/crop_screen.dart';

void main() {
  testWidgets('CropScreen renders header, guidance banner, and control buttons', (tester) async {
    final testFile = XFile('test_teeth.png');

    await tester.pumpWidget(
      MaterialApp(
        onGenerateRoute: (settings) {
          return MaterialPageRoute<void>(
            settings: RouteSettings(
              name: '/crop',
              arguments: CropScreenArguments(
                image: testFile,
                label: 'Front View (Center)',
              ),
            ),
            builder: (_) => const CropScreen(),
          );
        },
        initialRoute: '/crop',
      ),
    );

    expect(find.text('Crop Dental Photo'), findsOneWidget);
    expect(find.text('Front View (Center)'), findsOneWidget);
    expect(
      find.text(
        'Crop the image so only the teeth are visible. Remove unnecessary background such as lips, facial hair, cheeks, and skin where possible.',
      ),
      findsOneWidget,
    );
    expect(find.text('Skip Crop'), findsOneWidget);
    expect(find.text('Reset Crop'), findsOneWidget);
    expect(find.text('Apply & Save Crop'), findsOneWidget);
  });
}
