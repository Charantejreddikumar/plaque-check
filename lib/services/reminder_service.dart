import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderSettings {
  const ReminderSettings({
    required this.enabled,
    required this.frequency,
    required this.customDays,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final String frequency; // 'daily', 'every_2_days', 'weekly', 'custom'
  final int customDays;
  final int hour;
  final int minute;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);
}

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const String keyEnabled = 'scan_reminder_enabled';
  static const String keyFrequency = 'scan_reminder_frequency';
  static const String keyCustomDays = 'scan_reminder_custom_days';
  static const String keyHour = 'scan_reminder_hour';
  static const String keyMinute = 'scan_reminder_minute';

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
    } catch (_) {}

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'plaquecheck_scan_reminders',
        'PlaqueCheck Scan Reminders',
        description: 'Reminders for your scheduled dental plaque checks',
        importance: Importance.high,
      );

      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    bool granted = false;

    if (Platform.isAndroid) {
      final androidImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final res = await androidImpl?.requestNotificationsPermission();
      granted = res ?? false;
    } else if (Platform.isIOS) {
      final iosImpl = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      final res = await iosImpl?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = res ?? false;
    }

    return granted;
  }

  Future<ReminderSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(keyEnabled) ?? false;
    final frequency = prefs.getString(keyFrequency) ?? 'daily';
    final customDays = prefs.getInt(keyCustomDays) ?? 3;
    final hour = prefs.getInt(keyHour) ?? 9;
    final minute = prefs.getInt(keyMinute) ?? 0;

    return ReminderSettings(
      enabled: enabled,
      frequency: frequency,
      customDays: customDays,
      hour: hour,
      minute: minute,
    );
  }

  Future<void> saveAndRescheduleSettings(ReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyEnabled, settings.enabled);
    await prefs.setString(keyFrequency, settings.frequency);
    await prefs.setInt(keyCustomDays, settings.customDays);
    await prefs.setInt(keyHour, settings.hour);
    await prefs.setInt(keyMinute, settings.minute);

    await applySchedules(settings);
  }

  Future<void> cancelAllReminders() async {
    try {
      await initialize();
      await _notificationsPlugin.cancelAll();
    } catch (_) {}
  }

  Future<void> applySchedules(ReminderSettings settings) async {
    try {
      await initialize();
      await cancelAllReminders();

      if (!settings.enabled) return;

      const androidDetails = AndroidNotificationDetails(
        'plaquecheck_scan_reminders',
        'PlaqueCheck Scan Reminders',
        channelDescription: 'Reminders for your scheduled dental plaque checks',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      );

      const title = '🦷 Time for your PlaqueCheck Scan';
      const body = "Keep your smile healthy. It's time for your scheduled plaque scan.";

      final now = tz.TZDateTime.now(tz.local);
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        settings.hour,
        settings.minute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      if (settings.frequency == 'daily') {
        await _notificationsPlugin.zonedSchedule(
          1001,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (settings.frequency == 'weekly') {
        await _notificationsPlugin.zonedSchedule(
          1001,
          title,
          body,
          scheduledDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } else {
        final intervalDays = settings.frequency == 'every_2_days'
            ? 2
            : (settings.customDays > 0 ? settings.customDays : 3);

        for (int i = 0; i < 14; i++) {
          final nextDate = scheduledDate.add(Duration(days: i * intervalDays));
          await _notificationsPlugin.zonedSchedule(
            1000 + i,
            title,
            body,
            nextDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {}
  }
}
