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
import 'exact_alarm_service.dart';

class RoutineNotificationService {
  RoutineNotificationService({
    LocalNotificationGateway? gateway,
    Future<NotificationPreferences> Function()? preferencesLoader,
    Future<bool> Function()? exactAlarmsAllowed,
  })  : _gateway = gateway ?? FlutterLocalNotificationGateway(),
        _preferencesLoader =
            preferencesLoader ?? NotificationPreferencesStorage.load,
        _exactAlarmsAllowed = exactAlarmsAllowed ??
            ExactAlarmService.instance.canScheduleExactAlarms;

  final LocalNotificationGateway _gateway;
  final Future<NotificationPreferences> Function() _preferencesLoader;

  /// 정확 알람 권한 여부. 매 동기화마다 다시 묻는다 — 사용자가 시스템 설정에서
  /// 언제든 끌 수 있고, 껐다면 다음 예약부터 부정확 알람으로 후퇴해야 한다.
  final Future<bool> Function() _exactAlarmsAllowed;

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

    final exact = await _exactAlarmsAllowed();
    for (final routine in routines) {
      if (!routine.notificationEnabled) continue;
      await _scheduleRoutine(routine, prefs: prefs, l10n: l10n, exact: exact);
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

  /// 소리가 켜진 루틴 알림 채널.
  static const soundChannelId = 'routine_schedule_sound';

  /// 소리를 끈 루틴 알림 채널. 진동은 그대로 울린다.
  static const silentChannelId = 'routine_schedule_silent';

  Future<void> _scheduleRoutine(
    Routine routine, {
    required NotificationPreferences prefs,
    required AppLocalizations l10n,
    required bool exact,
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
        exact: exact,
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
    //
    // 소리는 채널당 하나로 고정된다. Android 8.0부터 채널 설정은 만들어진
    // 시점의 값으로 굳고, 같은 채널에 playSound만 바꿔 걸면 OS가 무시한다.
    // 그래서 소리용과 무음용을 다른 채널로 나눠 두고 설정에 따라 고른다.
    // 설정을 바꾸면 SettingsController가 알림을 다시 걸므로 곧바로 반영된다.
    final androidChannelId = soundEnabled ? soundChannelId : silentChannelId;
    final androidChannelName = soundEnabled
        ? l10n.notificationChannelName
        : l10n.notificationChannelNameSilent;
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
    required bool exact,
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
    required bool exact,
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
      // 정확 알람 권한이 없으면 부정확으로 후퇴한다. 권한 없이 exact 를 쓰면
      // Android 12+ 에서 SecurityException 으로 예약 자체가 실패한다.
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
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
