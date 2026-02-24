import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int weeklyReminderId = 1001;

  static const String _weeklyReminderChannelId = 'weekly_reminder';
  static const String _weeklyReminderChannelName = '주간 입력 리마인드';
  static const String _weeklyReminderChannelDescription =
      '매출/지출 입력을 주 1회 알려드려요.';

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('[TaxRadar] timezone 초기화 실패: $e');
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
      macOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _plugin.initialize(initializationSettings);
    _initialized = true;
  }

  static Future<bool> requestPermissionIfNeeded() async {
    bool? iosGranted;
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      iosGranted = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    bool? macosGranted;
    final macosPlugin = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macosPlugin != null) {
      macosGranted = await macosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    bool? androidGranted;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      androidGranted = await androidPlugin.requestNotificationsPermission();
    }

    final results =
        <bool?>[iosGranted, macosGranted, androidGranted].whereType<bool>();
    if (results.isEmpty) return true;
    return results.every((item) => item);
  }

  static Future<void> cancelWeeklyReminder() async {
    await _plugin.cancel(weeklyReminderId);
  }

  static Future<void> scheduleWeeklyReminder({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    final scheduled = _nextWeekdayTime(
      weekday: weekday,
      hour: hour,
      minute: minute,
    );

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _weeklyReminderChannelId,
        _weeklyReminderChannelName,
        channelDescription: _weeklyReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      weeklyReminderId,
      '이번 주 입력, 1분만!',
      '매출/지출을 업데이트하면 세금 예측이 더 정확해져요.',
      scheduled,
      notificationDetails,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static tz.TZDateTime _nextWeekdayTime({
    required int weekday,
    required int hour,
    required int minute,
  }) {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    final daysToAdd = (weekday - scheduled.weekday) % 7;
    scheduled = scheduled.add(Duration(days: daysToAdd));

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 7));
    }

    return scheduled;
  }
}
