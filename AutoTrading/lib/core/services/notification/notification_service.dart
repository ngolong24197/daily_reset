import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

class NotificationService {
  static const String _morningChannelId = 'daily_reset_morning';
  static const String _reflectionChannelId = 'daily_reset_reflection';
  static const String _morningChannelName = 'Morning Reminder';
  static const String _reflectionChannelName = 'Reflection Reminder';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_isMobile) return;

    // Initialize timezone data
    tz_data.initializeTimeZones();
    final timezoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _morningChannelId,
        _morningChannelName,
        description: 'Daily morning reminder',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _reflectionChannelId,
        _reflectionChannelName,
        description: 'Daily reflection reminder',
        importance: Importance.high,
      ));
    }
  }

  Future<void> scheduleMorningReminder(NotificationTime time) async {
    if (!_isMobile) return;
    await _plugin.zonedSchedule(
      0,
      'Time for your Morning Spark!',
      'Start your day with an inspiring quote.',
      _nextInstanceOfTime(time.hour, time.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _morningChannelId,
          _morningChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> scheduleReflectionReminder(NotificationTime time) async {
    if (!_isMobile) return;
    await _plugin.zonedSchedule(
      1,
      'Time for your Daily Reflection',
      'Reflect on your day and track your mood.',
      _nextInstanceOfTime(time.hour, time.minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _reflectionChannelId,
          _reflectionChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelMorningReminder() async {
    if (!_isMobile) return;
    await _plugin.cancel(0);
  }

  Future<void> cancelReflectionReminder() async {
    if (!_isMobile) return;
    await _plugin.cancel(1);
  }

  Future<void> cancelAll() async {
    if (!_isMobile) return;
    await _plugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

class NotificationTime {
  final int hour;
  final int minute;
  const NotificationTime({required this.hour, required this.minute});
}