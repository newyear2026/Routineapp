import 'package:routine_timer/application/services/notification_action_service.dart';
import 'package:routine_timer/data/local/local_settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/home/home_snapshot_builder.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/calendar/routine_calendar.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/models/routine_notification_target.dart';
import 'package:routine_timer/domain/routine_overlap/routine_schedule_overlap.dart';
import 'package:routine_timer/domain/services/routine_occurrences.dart';
import 'package:routine_timer/domain/services/routine_progress_service.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/validation/routine_form_validator.dart';
import 'package:routine_timer/widget_home/system_home_widget_timeline.dart';
import 'support/localization.dart';
import 'support/test_doubles.dart';
import 'support/routine_test_harness.dart';

const sleep = Routine(
    id: 'sleep',
    title: '잠자기',
    startMinutesFromMidnight: 1380,
    endMinutesFromMidnight: 420,
    repeatWeekdays: {1, 2, 3, 4, 5},
    colorValue: 0xFFA577F5,
    iconEmoji: '',
    type: RoutineType.sleep,
    notificationEnabled: false,
    wakeNotificationEnabled: true,
    updatedAtMs: 123);

class RecordingGateway extends NoopNotificationGateway {
  final weekly =
      <({int id, int weekday, TimeOfDay time, String payload, String body})>[];
  final once = <({DateTime at, String payload})>[];
  @override
  Future<void> scheduleOnce(
      {required int id,
      required String title,
      required String body,
      required DateTime whenLocal,
      required NotificationDetails details,
      required String payload,
      required bool exact}) async {
    once.add((at: whenLocal, payload: payload));
  }

  final cancelled = <int>[];
  final pending = <PendingNotificationRequest>[];
  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.removeWhere((p) => p.id == id);
  }

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => List.of(pending);
  @override
  Future<void> scheduleWeekly(
      {required int id,
      required String title,
      required String body,
      required int weekday,
      required TimeOfDay time,
      required NotificationDetails details,
      required String payload,
      required bool exact}) async {
    weekly.add(
        (id: id, weekday: weekday, time: time, payload: payload, body: body));
    pending.add(PendingNotificationRequest(id, title, body, payload));
  }
}

void main() {
  setUpRoutineTestEnvironment();
  test(
      'legacy names remain activities; sleep and both alarm settings round trip',
      () {
    final old = sleep.toJson()
      ..remove('type')
      ..remove('wakeNotificationEnabled');
    old['title'] = '수면';
    final activity = Routine.fromJson(old);
    expect(activity.type, RoutineType.activity);
    expect(activity.wakeNotificationEnabled, false);
    final restored = Routine.fromJson(sleep.toJson());
    expect(restored.type, RoutineType.sleep);
    expect(restored.notificationEnabled, false);
    expect(restored.wakeNotificationEnabled, true);
    expect(RoutineOccurrences.onDate(sleep, DateTime(2026, 10, 5)).toJson(),
        sleep.toJson());
  });

  test('취침 알림·알람 설정이 저장되고, 예전 기록은 꺼진 채로 읽힌다', () {
    final custom = sleep.copyWith(
        bedtimeReminderEnabled: true,
        bedtimeReminderLeadMinutes: 15,
        wakeAlarmEnabled: true);
    final restored = Routine.fromJson(custom.toJson());
    expect(restored.bedtimeReminderEnabled, isTrue);
    expect(restored.bedtimeReminderLeadMinutes, 15);
    expect(restored.wakeAlarmEnabled, isTrue);

    // 이 기능 전에 저장한 수면 루틴은 갑자기 울리기 시작하면 안 된다.
    final legacy = Routine.fromJson(sleep.toJson()
      ..remove('bedtimeReminderEnabled')
      ..remove('bedtimeReminderLeadMinutes')
      ..remove('wakeAlarmEnabled'));
    expect(legacy.bedtimeReminderEnabled, isFalse);
    expect(legacy.bedtimeReminderLeadMinutes, 30);
    expect(legacy.wakeAlarmEnabled, isFalse);

    // 고를 수 없는 값은 기본값으로 돌린다.
    expect(
        Routine.fromJson(custom.toJson()..['bedtimeReminderLeadMinutes'] = 45)
            .bedtimeReminderLeadMinutes,
        30);
  });

  test('weekday wake dates start Sunday night and stop Thursday night', () {
    for (var i = 0; i < 7; i++) {
      final bedtime = DateTime(2026, 10, 4 + i, 23);
      final morning = DateTime(2026, 10, 5 + i, 6);
      expect(RoutineOccurrences.active(sleep, bedtime), i < 5);
      expect(RoutineOccurrences.active(sleep, morning), i < 5);
    }
    expect(RoutineOccurrences.active(sleep, DateTime(2026, 10, 9, 23)), false);
    expect(RoutineOccurrences.active(sleep, DateTime(2026, 10, 10, 6)), false);
  });

  for (final date in [
    DateTime(2027, 1, 1),
    DateTime(2026, 11, 1),
    DateTime(2028, 3, 1)
  ]) {
    test('calendar arithmetic crosses month/year/leap boundary $date', () {
      final r = RoutineOccurrences.onDate(
          sleep.copyWith(repeatWeekdays: {date.weekday}), date);
      final w = RoutineOccurrences.window(r, date);
      expect(w.start, DateTime(date.year, date.month, date.day - 1, 23));
      expect(w.end, DateTime(date.year, date.month, date.day, 7));
    });
  }

  test('23 to 00 is one hour and completes on next date; same times rejected',
      () {
    final r = sleep.copyWith(endMinutesFromMidnight: 0);
    expect(r.durationMinutes, 60);
    expect(RoutineOccurrences.active(r, DateTime(2026, 10, 4, 23, 59)), true);
    expect(RoutineOccurrences.active(r, DateTime(2026, 10, 5)), false);
    expect(RoutineFormValidator.validateSleepTimeRange(1380, 0), isNull);
    for (final minute in [0, 420, 1380]) {
      expect(RoutineFormValidator.validateSleepTimeRange(minute, minute),
          RoutineFormError.equalSleepTimes);
    }
    expect(RoutineFormValidator.validateTimeRange(1380, 420),
        RoutineFormError.endBeforeStart);
    expect(RoutineFormValidator.validateTimeRange(1380, 1440), isNull);
  });

  test('daytime sleep retains wake weekday without previous-night shift', () {
    final r = sleep.copyWith(
        startMinutesFromMidnight: 60, endMinutesFromMidnight: 480);
    expect(RoutineOccurrences.active(r, DateTime(2026, 10, 4, 23)), false);
    expect(RoutineOccurrences.active(r, DateTime(2026, 10, 5, 2)), true);
  });

  test('calendar and ring split two distinct sleep occurrences at midnight',
      () {
    final sunday =
        RoutineCalendar.routinesForDate(DateTime(2026, 10, 4), [sleep]);
    expect(sunday, hasLength(1));
    expect(sunday.single.occurrenceDate, DateTime(2026, 10, 5));
    final mon = RoutineCalendar.routinesForDate(DateTime(2026, 10, 5), [sleep]);
    expect(mon.map((r) => r.occurrenceDate),
        [DateTime(2026, 10, 5), DateTime(2026, 10, 6)]);
    final h = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 10, 5, 23, 30),
        allRoutines: [sleep],
        logsToday: []);
    expect(
        h.segments
            .map((s) => (s.startMinutesFromMidnight, s.endMinutesFromMidnight)),
        [(0, 420), (1380, 1440)]);
    expect(h.segments.map((s) => s.id).toSet(), hasLength(2));
    expect(h.currentRoutine!.occurrenceDate, DateTime(2026, 10, 6));
    expect(h.totalCount, 1);
  });

  test(
      'next activity follows sleep across midnight without changing ordinary horizons',
      () {
    final breakfast = sleep.copyWith(
        id: 'breakfast',
        type: RoutineType.activity,
        startMinutesFromMidnight: 420,
        endMinutesFromMidnight: 480,
        repeatWeekdays: {1});
    final h = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 10, 4, 23, 30),
        allRoutines: [sleep, breakfast],
        logsToday: []);
    expect(h.currentRoutine!.id, 'sleep');
    expect(h.nextRoutine!.id, 'breakfast');
    expect(h.nextAfterDisplay!.occurrenceDate, DateTime(2026, 10, 5));
    expect(h.todayRoutines.map((r) => r.id), ['sleep']);
    final day = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 10, 4, 23, 30),
        allRoutines: [breakfast],
        logsToday: []);
    expect(day.nextRoutine, isNull);
  });

  test('next skips routines that already started inside a long sleep', () {
    // 23:00 → 15:02 수면 중(수 14:58)이면 07:00 기상과 14:00 휴식은 이미 시작했다.
    final longSleep = sleep.copyWith(endMinutesFromMidnight: 902);
    Routine activity(String id, int start, int end) => sleep.copyWith(
        id: id,
        type: RoutineType.activity,
        startMinutesFromMidnight: start,
        endMinutesFromMidnight: end,
        repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
        updatedAtMs: 1);
    final h = HomeSnapshotBuilder.build(
        l10n: testL10n,
        nowLocal: DateTime(2026, 10, 7, 14, 58),
        allRoutines: [
          longSleep,
          activity('wake', 420, 450),
          activity('rest', 840, 960),
          activity('dinner', 1080, 1140),
        ],
        logsToday: []);
    expect(h.currentRoutine!.id, 'sleep');
    expect(h.nextRoutine!.id, 'dinner');
    expect(h.nextAfterDisplay!.id, 'dinner');
    expect(h.upcomingRoutines.map((r) => r.id), isNot(contains('wake')));
    expect(h.upcomingRoutines.map((r) => r.id), isNot(contains('rest')));
  });

  test('elapsed sleep progress uses one continuous overnight window', () {
    const progress = RoutineProgressService();
    expect(
        progress.progressPercentInWindow(sleep, DateTime(2026, 10, 4, 23)), 0);
    expect(
        progress.progressPercentInWindow(sleep, DateTime(2026, 10, 5, 3)), 50);
    expect(
        progress.progressPercentInWindow(sleep, DateTime(2026, 10, 5, 7)), 100);
  });

  test(
      'overlaps include previous evening and wake morning but exclude adjacent boundaries',
      () {
    Routine activity(int day, int start, int end) => sleep.copyWith(
        id: 'activity',
        type: RoutineType.activity,
        startMinutesFromMidnight: start,
        endMinutesFromMidnight: end,
        repeatWeekdays: {day});
    expect(
        RoutineScheduleOverlap.routinesOverlapOnSharedDay(
            sleep, activity(7, 1410, 1440)),
        true);
    expect(
        RoutineScheduleOverlap.routinesOverlapOnSharedDay(
            sleep, activity(1, 360, 480)),
        true);
    expect(
        RoutineScheduleOverlap.routinesOverlapOnSharedDay(
            sleep, activity(5, 1410, 1440)),
        false);
    expect(
        RoutineScheduleOverlap.routinesOverlapOnSharedDay(
            sleep, activity(6, 360, 480)),
        false);
    expect(
        RoutineScheduleOverlap.routinesOverlapOnSharedDay(
            sleep, activity(1, 420, 480)),
        false);
    expect(
        RoutineScheduleOverlap.conflictingRoutines(
            candidate: sleep, allRoutines: [sleep], excludeRoutineId: sleep.id),
        isEmpty);
  });

  test(
      'completion before midnight stays on wake date and does not complete next sleep',
      () async {
    var now = DateTime(2026, 10, 4, 23, 30);
    final logs = MemoryLogRepository();
    final app = RoutineAppController(
        nowProvider: () => now,
        clockAutoRefreshEnabled: false,
        dataService: RoutineDataService(
            routineRepository: MemoryRoutineRepository([sleep]),
            logRepository: logs),
        completionHaptic: () async {},
        notificationService: RoutineNotificationService(
            gateway: NoopNotificationGateway(),
            exactAlarmsAllowed: () async => false,
            preferencesLoader: () async =>
                NotificationPreferences.firstLaunchDefaults));
    addTearDown(app.dispose);
    await app.load();
    final undo = await app.completeCurrent();
    expect(undo!.dateYmd, '2026-10-05');
    expect(logs.logs.single.dateYmd, '2026-10-05');
    now = DateTime(2026, 10, 5, 0, 10);
    await app.refreshClockStateForTest();
    expect(app.homeSnapshotFor(testL10n).currentRoutineLogStatus,
        RoutineLogStatus.completed);
    expect(app.progressSummary.completed, 1);
    now = DateTime(2026, 10, 5, 23, 30);
    await app.refreshClockStateForTest();
    expect(app.canActOnCurrentSlot, true);
    await app.skipCurrent();
    expect(logs.logs.map((l) => l.dateYmd), ['2026-10-05', '2026-10-06']);
    await app.undoAction(undo);
    expect(logs.logs.single.dateYmd, '2026-10-06');
  });

  test('sleep wake alerts use end time; activity alerts retain start time',
      () async {
    final gateway = RecordingGateway();
    final service = RoutineNotificationService(
        gateway: gateway,
        exactAlarmsAllowed: () async => false,
        preferencesLoader: () async => const NotificationPreferences(
            notificationsEnabled: true,
            soundEnabled: true,
            permissionStatus: NotificationPermissionStatus.granted));
    final normal = sleep.copyWith(
        id: 'normal',
        type: RoutineType.activity,
        notificationEnabled: true,
        startMinutesFromMidnight: 540,
        endMinutesFromMidnight: 600,
        repeatWeekdays: {1});
    await service.syncAll([sleep, normal], testL10n);
    expect(gateway.weekly.take(5).map((a) => a.weekday), [1, 2, 3, 4, 5]);
    expect(
        gateway.weekly
            .take(5)
            .every((a) => a.time == const TimeOfDay(hour: 7, minute: 0)),
        true);
    expect(gateway.weekly.last.time, const TimeOfDay(hour: 9, minute: 0));
    final target =
        RoutineNotificationTarget.parse(gateway.weekly.first.payload)!;
    expect(target.occurrenceDate(DateTime(2026, 10, 5, 7)), '2026-10-05');
    expect(target.matches(sleep), true);
    final zero = RoutineNotificationTarget.forRoutine(
        sleep.copyWith(endMinutesFromMidnight: 0),
        weekday: 1);
    expect(zero.occurrenceDate(DateTime(2026, 10, 5)), '2026-10-05');
    gateway.weekly.clear();
    await service
        .syncAll([sleep.copyWith(wakeNotificationEnabled: false)], testL10n);
    expect(gateway.weekly, isEmpty);
    expect(gateway.pending, isEmpty);
  });

  test(
      'edit/delete cancels stale wake and snooze reservations; denied permission stays quiet',
      () async {
    final gateway = RecordingGateway();
    var granted = true;
    final service = RoutineNotificationService(
        gateway: gateway,
        exactAlarmsAllowed: () async => false,
        preferencesLoader: () async => NotificationPreferences(
            notificationsEnabled: true,
            soundEnabled: true,
            permissionStatus: granted
                ? NotificationPermissionStatus.granted
                : NotificationPermissionStatus.denied));
    await service.syncAll([sleep], testL10n);
    gateway.pending.add(PendingNotificationRequest(
        99,
        '',
        '',
        RoutineNotificationTarget.forRoutine(sleep, dateYmd: '2026-10-05')
            .encode(snooze: true)));
    gateway.weekly.clear();
    await service.syncAll(
        [sleep.copyWith(endMinutesFromMidnight: 480, updatedAtMs: 124)],
        testL10n);
    expect(gateway.cancelled, contains(99));
    expect(gateway.weekly.every((a) => a.time.hour == 8), true);
    await service.syncAll([], testL10n);
    expect(gateway.pending, isEmpty);
    gateway.weekly.clear();
    granted = false;
    await service.syncAll([sleep], testL10n);
    expect(gateway.weekly, isEmpty);
  });

  test(
      'wake notification snooze and completion use wake date after the sleep window ends',
      () async {
    await LocalSettingsRepository.instance.saveNotificationPreferences(
        const NotificationPreferences(
            notificationsEnabled: true,
            soundEnabled: true,
            permissionStatus: NotificationPermissionStatus.granted));
    final logs = MemoryLogRepository();
    final gateway = RecordingGateway();
    final routines = MemoryRoutineRepository([sleep]);
    final notifications = RoutineNotificationService(
        gateway: gateway, exactAlarmsAllowed: () async => false);
    final actions = NotificationActionService(
        routines: routines, logs: logs, notifications: notifications);
    final posted = DateTime(2026, 10, 5, 7);
    final target = RoutineNotificationTarget.forRoutine(sleep, weekday: 1);
    expect(
        await actions.snooze(
            target: target, postedAt: posted, now: posted, l10n: testL10n),
        true);
    expect(logs.logs.single.dateYmd, '2026-10-05');
    expect(gateway.once.single.at, DateTime(2026, 10, 5, 7, 15));
    expect(
        await actions.snooze(
            target: target,
            postedAt: posted,
            now: DateTime(2026, 10, 6, 7),
            l10n: testL10n),
        false);
    final app = RoutineAppController(
        dataService: RoutineDataService(
            routineRepository: routines, logRepository: logs),
        nowProvider: () => DateTime(2026, 10, 5, 7, 16),
        clockAutoRefreshEnabled: false,
        completionHaptic: () async {},
        notificationService: notifications);
    addTearDown(app.dispose);
    await app.load();
    final undo = await app.completeNotificationRoutine('sleep', '2026-10-05');
    expect(undo, isNotNull);
    expect(logs.logs.single.status, RoutineLogStatus.completed);
    expect(app.progressSummary.completed, 1);
    expect(
        await actions.snooze(
            target: target,
            postedAt: posted,
            now: DateTime(2026, 10, 5, 7, 17),
            l10n: testL10n),
        false);
  });

  test(
      'editing preserves type and log date; deleting removes sleep and its records',
      () async {
    final logs = MemoryLogRepository();
    final app = createTestRoutineController(
        now: DateTime(2026, 10, 5, 1), routines: [sleep], logRepository: logs);
    addTearDown(app.dispose);
    await app.load();
    await app.skipCurrent();
    await app.saveRoutine(sleep.copyWith(endMinutesFromMidnight: 480));
    expect(app.routines.single.type, RoutineType.sleep);
    expect(app.todayLogs.single.dateYmd, '2026-10-05');
    await app.deleteRoutine('sleep');
    expect(app.routines, isEmpty);
    expect(logs.logs, isEmpty);
  });

  test('controller rejects ambiguous equal times even outside the form',
      () async {
    final app =
        createTestRoutineController(now: DateTime(2026, 10, 5), routines: []);
    addTearDown(app.dispose);
    await app.load();
    await app.saveRoutine(sleep.copyWith(endMinutesFromMidnight: 1380));
    expect(app.routines, isEmpty);
  });

  test('widget timeline carries overnight wake target across midnight', () {
    final result = SystemHomeWidgetTimeline.build(
        now: DateTime(2026, 10, 4, 23, 30),
        l10n: testL10n,
        routines: [sleep],
        logsToday: []);
    final json = result.toJson();
    expect(json.toString(),
        contains(DateTime(2026, 10, 5, 7).millisecondsSinceEpoch.toString()));
  });
}
