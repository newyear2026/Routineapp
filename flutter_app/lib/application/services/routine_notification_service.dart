import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:routine_notification_platform/routine_notification_platform.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/models/routine.dart';
import '../../domain/validation/routine_form_validator.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/models/routine_notification_target.dart';
import '../../domain/utils/time_minutes.dart';
import '../../domain/settings/notification_permission_status.dart';
import '../../domain/settings/notification_preferences.dart';
import '../../data/local/notification_preferences_storage.dart';
import '../../l10n/app_localizations.dart';
import 'exact_alarm_service.dart';
import 'notification_runtime.dart';

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

  /// «나중에»로 미뤄둔 1회성 재알림. 주간 예약과 접두사를 나눠 두는 이유는
  /// [syncAll]이 자기 것만 지우고 다시 걸기 때문이다. 같은 접두사를 쓰면
  /// 루틴을 저장하거나 설정을 건드릴 때마다 미뤄둔 알림이 조용히 사라진다.
  static const snoozePayloadPrefix = 'routine_snooze:';

  /// [l10n]은 알림 문구에 쓸 현재 언어다. 알림은 위젯 트리 밖에서 예약되므로
  /// 호출자가 넘겨준다(컨트롤러의 `strings`).
  Future<void> syncAll(List<Routine> routines, AppLocalizations l10n) async {
    if (kIsWeb) return;

    await _gateway.initialize();
    await _cancelManagedPendingNotifications();

    final prefs = await _preferencesLoader();
    if (!_appNotificationsAvailable(prefs)) {
      // 알림을 끈 사람에게 미뤄둔 재알림만 남아 울리면 안 된다.
      // 주간 예약과 달리 이건 위에서 지우지 않으므로 여기서 거둔다.
      await _cancelPendingSnoozes();
      return;
    }

    await _cancelInvalidPendingSnoozes(routines);
    final exact = await _exactAlarmsAllowed();
    for (final routine in routines) {
      if (!routine.alertsEnabled) continue;
      if (routine.isSleep &&
          RoutineFormValidator.validateSleepTimeRange(
                  routine.startMinutesFromMidnight,
                  routine.endMinutesFromMidnight) !=
              null) {
        continue;
      }
      await _scheduleRoutine(routine, prefs: prefs, l10n: l10n, exact: exact);
    }
  }

  bool _appNotificationsAvailable(NotificationPreferences prefs) {
    return prefs.notificationsEnabled &&
        prefs.permissionStatus == NotificationPermissionStatus.granted;
  }

  /// 주간 예약만 지운다. 바로 아래에서 다시 걸 것들이다.
  ///
  /// 미뤄둔 재알림은 **일부러 건드리지 않는다.** 사용자가 «나중에»를 눌러
  /// 정한 오늘 한 번짜리 약속이라, 루틴을 저장했다고 없어지면 안 된다.
  Future<void> _cancelManagedPendingNotifications() async {
    final pending = await _gateway.pendingNotificationRequests();
    for (final request in pending) {
      if (isManagedPayload(request.payload)) {
        await _gateway.cancel(request.id);
      }
    }
  }

  Future<void> _cancelPendingSnoozes() async {
    final pending = await _gateway.pendingNotificationRequests();
    for (final request in pending) {
      if (isSnoozePayload(request.payload)) {
        await _gateway.cancel(request.id);
      }
    }
  }

  /// 삭제하거나 개별 알림을 끈 루틴의 재알림은 남기지 않는다.
  /// 다른 루틴을 저장한 경우에는 기존에 약속한 재알림 시각을 유지한다.
  Future<void> _cancelInvalidPendingSnoozes(List<Routine> routines) async {
    final enabledIds = {
      for (final routine in routines)
        if (routine.alertsEnabled) routine.id,
    };
    final pending = await _gateway.pendingNotificationRequests();
    for (final request in pending.where((p) => isSnoozePayload(p.payload))) {
      final target = RoutineNotificationTarget.parse(request.payload);
      final id = target?.routineId;
      final routine = routines.where((r) => r.id == id).firstOrNull;
      final changed = target?.updatedAtMs != null &&
          routine != null &&
          !target!.matches(routine);
      if (!enabledIds.contains(id) || changed) {
        await _gateway.cancel(request.id);
      }
    }
  }

  /// «나중에»로 미뤄둔 루틴을 [whenLocal]에 한 번 다시 알린다.
  ///
  /// 루틴별 알림 설정을 끈 루틴은 걸지 않는다. 원래 알림도 가지 않는
  /// 루틴인데 미뤘다고 울리면 설정을 어기는 셈이다.
  Future<void> scheduleSnooze(
    Routine routine,
    DateTime whenLocal,
    AppLocalizations l10n, {
    String? occurrenceDate,
  }) async {
    if (kIsWeb) return;

    await _gateway.initialize();
    final prefs = await _preferencesLoader();
    if (!_appNotificationsAvailable(prefs) || !routine.alertsEnabled) {
      await _gateway.cancel(snoozeNotificationIdFor(routine.id));
      return;
    }

    await _gateway.scheduleOnce(
      id: snoozeNotificationIdFor(routine.id),
      title: routine.title,
      body: l10n.notificationSnoozeBody(routine.title),
      whenLocal: whenLocal,
      details: _notificationDetails(
        mode: prefs.mode,
        l10n: l10n,
      ),
      payload: RoutineNotificationTarget.forRoutine(routine,
              dateYmd: occurrenceDate ?? TimeMinutes.dateYmd(whenLocal))
          .encode(snooze: true),
      exact: await _exactAlarmsAllowed(),
    );
  }

  /// 미뤄둔 재알림을 거둔다 — 완료·건너뛰기로 끝났거나 되돌렸을 때.
  Future<void> cancelSnooze(String routineId) async {
    if (kIsWeb) return;

    await _gateway.initialize();
    await _gateway.cancel(snoozeNotificationIdFor(routineId));
  }

  /// 소리가 켜진 루틴 알림 채널.
  static const soundChannelId = 'routine_schedule_sound';

  /// 소리를 끈 루틴 알림 채널. 진동은 그대로 울린다.
  static const silentChannelId = 'routine_schedule_silent';

  /// 기존 무음 채널은 진동이 켜져 있으므로 화면 전용 채널은 따로 둔다.
  static const visualChannelId = 'routine_schedule_visual';
  static const previewNotificationId = 0x7ffffffe;

  Future<void> _scheduleRoutine(
    Routine routine, {
    required NotificationPreferences prefs,
    required AppLocalizations l10n,
    required bool exact,
  }) async {
    final notificationDetails = _notificationDetails(
      mode: prefs.mode,
      l10n: l10n,
    );
    final sortedWeekdays = routine.repeatWeekdays.toList()..sort();
    for (final weekday in sortedWeekdays) {
      await _gateway.scheduleWeekly(
        id: notificationIdFor(routine.id, weekday),
        title: routine.title,
        body: routine.isSleep
            ? l10n.sleepWakeNotificationBody
            : l10n.notificationBody(routine.title),
        weekday: weekday,
        time: TimeOfDay(
          hour: (routine.isSleep
                  ? routine.endMinutesFromMidnight
                  : routine.startMinutesFromMidnight) ~/
              60,
          minute: (routine.isSleep
                  ? routine.endMinutesFromMidnight
                  : routine.startMinutesFromMidnight) %
              60,
        ),
        details: notificationDetails,
        payload: RoutineNotificationTarget.forRoutine(routine, weekday: weekday)
            .encode(snooze: false),
        exact: exact,
      );
    }
  }

  NotificationDetails _notificationDetails({
    required RoutineNotificationMode mode,
    required AppLocalizations l10n,
    bool routineActions = true,
  }) {
    // 채널 ID는 고정이다. 언어가 바뀌어도 같은 채널을 계속 쓴다 —
    // ID를 번역하면 언어를 바꿀 때마다 새 채널이 생기고, 사용자가 예전 채널에서
    // 꺼둔 설정이 조용히 무시된다.
    //
    // 소리는 채널당 하나로 고정된다. Android 8.0부터 채널 설정은 만들어진
    // 시점의 값으로 굳고, 같은 채널에 playSound만 바꿔 걸면 OS가 무시한다.
    // 그래서 소리용과 무음용을 다른 채널로 나눠 두고 설정에 따라 고른다.
    // 설정을 바꾸면 SettingsController가 알림을 다시 걸므로 곧바로 반영된다.
    final soundEnabled = mode == RoutineNotificationMode.soundAndVibration;
    final vibrationEnabled = mode != RoutineNotificationMode.visualOnly;
    final androidChannelId = switch (mode) {
      RoutineNotificationMode.soundAndVibration => soundChannelId,
      RoutineNotificationMode.vibrationOnly => silentChannelId,
      RoutineNotificationMode.visualOnly => visualChannelId,
    };
    final androidChannelName = switch (mode) {
      RoutineNotificationMode.soundAndVibration => l10n.notificationChannelName,
      RoutineNotificationMode.vibrationOnly =>
        l10n.notificationChannelNameSilent,
      RoutineNotificationMode.visualOnly => l10n.notificationChannelVisual,
    };
    final androidChannelDescription = l10n.notificationChannelDesc;

    final android = AndroidNotificationDetails(
      androidChannelId,
      androidChannelName,
      channelDescription: androidChannelDescription,
      importance: Importance.max,
      priority: Priority.high,
      playSound: soundEnabled,
      enableVibration: vibrationEnabled,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('ic_notification_large'),
      color: const Color(0xFF6841F5),
      // Keep the delivered occurrence available until our handler reads its date.
      autoCancel: false,
      actions: [
        AndroidNotificationAction(
            notificationAcknowledgeAction, l10n.notificationActionAcknowledge,
            cancelNotification: false),
        if (routineActions)
          AndroidNotificationAction(
              notificationSnoozeAction, l10n.notificationActionSnooze,
              cancelNotification: false),
      ],
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

  /// 설정 변경 시 남아 있는 재알림만 원래 시각 그대로 다시 예약한다.
  /// 이미 울린 재알림을 로그만 보고 되살리지 않는다.
  Future<void> refreshPendingSnoozes(
    List<Routine> routines,
    List<RoutineLog> logs,
    AppLocalizations l10n, {
    DateTime? now,
  }) async {
    if (kIsWeb) return;
    await _gateway.initialize();
    final pending = await _gateway.pendingNotificationRequests();
    final currentTime = now ?? DateTime.now();
    final byId = {for (final routine in routines) routine.id: routine};
    for (final request in pending.where((p) => isSnoozePayload(p.payload))) {
      final routineId =
          RoutineNotificationTarget.parse(request.payload)?.routineId;
      final routine = byId[routineId];
      final matches = logs
          .where((log) =>
              log.routineId == routineId &&
              log.status == RoutineLogStatus.snoozed &&
              log.snoozedUntilMs != null &&
              log.snoozedUntilMs! > currentTime.millisecondsSinceEpoch)
          .toList()
        ..sort((a, b) => b.snoozedUntilMs!.compareTo(a.snoozedUntilMs!));
      if (routine == null || !routine.alertsEnabled || matches.isEmpty) {
        await _gateway.cancel(request.id);
        continue;
      }
      await scheduleSnooze(
          routine,
          DateTime.fromMillisecondsSinceEpoch(matches.first.snoozedUntilMs!),
          l10n,
          occurrenceDate: matches.first.dateYmd);
    }
  }

  /// 실제 루틴과 동일한 채널로 즉시 게시한다. 미디어 소리/임의 진동을
  /// 재생하지 않아 휴대폰 무음·방해금지·채널 설정을 그대로 따른다.
  Future<void> showPreview(AppLocalizations l10n) async {
    if (kIsWeb) throw UnsupportedError('Notifications require a mobile device');
    final prefs = await _preferencesLoader();
    if (!_appNotificationsAvailable(prefs)) {
      throw StateError('Notifications are disabled');
    }
    await _gateway.initialize();
    await _gateway.cancel(previewNotificationId);
    await _gateway.show(
      id: previewNotificationId,
      title: l10n.notificationPreviewTitle,
      body: l10n.notificationPreviewBody,
      details: _notificationDetails(
          mode: prefs.mode, l10n: l10n, routineActions: false),
    );
  }

  static String payloadFor(String routineId, int weekday) =>
      '$managedPayloadPrefix$routineId:$weekday';

  static bool isManagedPayload(String? payload) =>
      payload != null && payload.startsWith(managedPayloadPrefix);

  static String snoozePayloadFor(String routineId) =>
      '$snoozePayloadPrefix$routineId';

  static bool isSnoozePayload(String? payload) =>
      payload != null && payload.startsWith(snoozePayloadPrefix);

  static int notificationIdFor(String routineId, int weekday) =>
      _fnv1a('$routineId:$weekday');

  /// 미뤄둔 재알림은 루틴마다 하나다. 다시 미루면 같은 id 로 덮어써
  /// 마지막으로 정한 시각 하나만 남는다.
  static int snoozeNotificationIdFor(String routineId) =>
      _fnv1a('$snoozePayloadPrefix$routineId');

  static int _fnv1a(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

abstract class LocalNotificationGateway {
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  });

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

  /// 한 번만 울리는 예약. 반복하지 않는다.
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
    required NotificationDetails details,
    required String payload,
    required bool exact,
  });

  Future<void> cancel(int id);

  Future<List<PendingNotificationRequest>> pendingNotificationRequests();
}

class FlutterLocalNotificationGateway implements LocalNotificationGateway {
  FlutterLocalNotificationsPlugin get _plugin =>
      NotificationRuntime.instance.plugin;
  static const MethodChannel _timezoneChannel =
      MethodChannel('routine_timer/device_timezone');

  bool _initialized = false;
  bool _timezonesInitialized = false;

  @override
  Future<void> initialize() async {
    if (kIsWeb || _initialized) return;

    await NotificationRuntime.instance.initialize();
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
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: details,
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
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
    required NotificationDetails details,
    required String payload,
    required bool exact,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(whenLocal, tz.local),
      notificationDetails: details,
      androidScheduleMode: exact
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
      // matchDateTimeComponents 를 주지 않는다. 주면 매주 같은 시각에
      // 다시 울린다 — 오늘 한 번 미룬 것뿐이다.
    );
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationDetails details,
  }) =>
      _plugin.show(
          id: id,
          title: title,
          body: body,
          notificationDetails: details,
          payload: 'routine_preview');

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

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
    if (defaultTargetPlatform == TargetPlatform.android) {
      return RoutineNotificationPlatform.timezone();
    }
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

    while (scheduledDate.weekday != weekday ||
        scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      scheduledDate = tz.TZDateTime(tz.local, scheduledDate.year,
          scheduledDate.month, scheduledDate.day + 1, time.hour, time.minute);
    }
    return scheduledDate;
  }
}
