import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/routine.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/notification_preferences.dart';
import '../../data/local/notification_preferences_storage.dart';
import '../../l10n/app_localizations.dart';

class RoutineNotificationService {
  RoutineNotificationService({
    LocalNotificationGateway? gateway,
    Future<NotificationPreferences> Function()? preferencesLoader,
  })  : _gateway = gateway ?? FlutterLocalNotificationGateway(),
        _preferencesLoader =
            preferencesLoader ?? NotificationPreferencesStorage.load;

  final LocalNotificationGateway _gateway;
  final Future<NotificationPreferences> Function() _preferencesLoader;

  static const managedPayloadPrefix = 'routine_notification:';

  /// [l10n]은 알림 문구에 쓸 현재 언어다. 알림은 위젯 트리 밖에서 예약되므로
  /// 호출자가 넘겨준다(컨트롤러의 `strings`).
  Future<void> syncAll(List<Routine> routines, AppLocalizations l10n) async {
    if (kIsWeb) return;

    await _gateway.initialize();
    await _cancelManagedPendingNotifications();

    final prefs = await _preferencesLoader();
    if (!_appNotificationsAvailable(prefs)) {
      return;
    }

    for (final routine in routines) {
      if (!routine.notificationEnabled) continue;
      await _scheduleRoutine(routine, prefs: prefs, l10n: l10n);
    }
  }

  bool _appNotificationsAvailable(NotificationPreferences prefs) {
    return prefs.notificationsEnabled &&
        prefs.permissionStatus == NotificationPermissionStatus.granted;
  }

  Future<void> _cancelManagedPendingNotifications() async {
    final pending = await _gateway.pendingNotificationRequests();
    for (final request in pending) {
      if (isManagedPayload(request.payload)) {
        await _gateway.cancel(request.id);
      }
    }
  }

  Future<void> _scheduleRoutine(
    Routine routine, {
    required NotificationPreferences prefs,
    required AppLocalizations l10n,
  }) async {
    final notificationDetails = _notificationDetails(
      soundEnabled: prefs.soundEnabled,
      l10n: l10n,
    );
    final sortedWeekdays = routine.repeatWeekdays.toList()..sort();
    for (final weekday in sortedWeekdays) {
      await _gateway.scheduleWeekly(
        id: notificationIdFor(routine.id, weekday),
        title: routine.title,
        body: l10n.notificationBody(routine.title),
        weekday: weekday,
        time: TimeOfDay(
          hour: routine.startMinutesFromMidnight ~/ 60,
          minute: routine.startMinutesFromMidnight % 60,
        ),
        details: notificationDetails,
        payload: payloadFor(routine.id, weekday),
      );
    }
  }

  NotificationDetails _notificationDetails({
    required bool soundEnabled,
    required AppLocalizations l10n,
  }) {
    // 채널 ID는 고정이다. 언어가 바뀌어도 같은 채널을 계속 쓴다 —
    // ID를 번역하면 언어를 바꿀 때마다 새 채널이 생기고, 사용자가 예전 채널에서
    // 꺼둔 설정이 조용히 무시된다.
    const androidChannelId = 'routine_schedule';
    final androidChannelName = l10n.notificationChannelName;
    final androidChannelDescription = l10n.notificationChannelDesc;

    final android = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: true,
    );
    final darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: soundEnabled,
    );
    return NotificationDetails(
      android: android,
      iOS: darwin,
      macOS: darwin,
    );
  }

  static String payloadFor(String routineId, int weekday) =>
      '$managedPayloadPrefix$routineId:$weekday';

  static bool isManagedPayload(String? payload) =>
      payload != null && payload.startsWith(managedPayloadPrefix);

  static int notificationIdFor(String routineId, int weekday) {
    var hash = 0x811c9dc5;
    final key = '$routineId:$weekday';
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

abstract class LocalNotificationGateway {
  Future<void> initialize();

  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    required NotificationDetails details,
    required String payload,
  });

  Future<void> cancel(int id);

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();
}

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _timezoneChannel =
      MethodChannel('routine_timer/device_timezone');

  bool _initialized = false;
  bool _timezonesInitialized = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );
    await _ensureTimezoneInitialized();
    _initialized = true;
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    required NotificationDetails details,
    required String payload,
  }) async {
    final scheduledDate = _nextInstanceOfWeekdayTime(
      weekday: weekday,
      time: time,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() =>
      _plugin.pendingNotificationRequests();

  Future<void> _ensureTimezoneInitialized() async {
    if (_timezonesInitialized) return;

    tz_data.initializeTimeZones();
    final timezoneName = await _deviceTimezoneName();
    if (timezoneName != null && timezoneName.isNotEmpty) {
      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
      } on ArgumentError {
        // Keep timezone package default if the platform returned an unknown id.
      }
    }
    _timezonesInitialized = true;
  }

  Future<String?> _deviceTimezoneName() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return null;
    }
    return _timezoneChannel.invokeMethod<String>('getLocalTimezone');
  }

  tz.TZDateTime _nextInstanceOfWeekdayTime({
    required int weekday,
    required TimeOfDay time,
  }) {
    var scheduledDate = tz.TZDateTime.now(tz.local);
    scheduledDate = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      time.hour,
      time.minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
