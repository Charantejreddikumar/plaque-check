import 'package:flutter_test/flutter_test.dart';
import 'package:plaquecheck/services/reminder_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ReminderService loads default settings when unconfigured', () async {
    final service = ReminderService();
    final settings = await service.loadSettings();

    expect(settings.enabled, false);
    expect(settings.frequency, 'daily');
    expect(settings.customDays, 3);
    expect(settings.hour, 9);
    expect(settings.minute, 0);
  });

  test('ReminderService saves and reloads updated reminder settings', () async {
    final service = ReminderService();
    const newSettings = ReminderSettings(
      enabled: true,
      frequency: 'weekly',
      customDays: 5,
      hour: 20,
      minute: 30,
    );

    await service.saveAndRescheduleSettings(newSettings);
    final reloaded = await service.loadSettings();

    expect(reloaded.enabled, true);
    expect(reloaded.frequency, 'weekly');
    expect(reloaded.customDays, 5);
    expect(reloaded.hour, 20);
    expect(reloaded.minute, 30);
  });
}
