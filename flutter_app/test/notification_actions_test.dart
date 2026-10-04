import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_notification_platform/routine_notification_platform.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/notification_action_service.dart';
import 'package:routine_timer/application/services/notification_runtime.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/local/local_settings_repository.dart';
import 'package:routine_timer/domain/models/routine_action_source.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/models/routine_notification_target.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final now = DateTime(2026, 10, 4, 9, 5);
  final posted = DateTime(2026, 10, 4, 9);
  final reading =
      dailyRoutine(id: 'reading', title: '독서', startHour: 9, endHour: 10);
  final other = dailyRoutine(
      id: 'other', title: '운동', startHour: 9, endHour: 10, updatedAtMs: 2);
  final target =
      RoutineNotificationTarget.forRoutine(reading, weekday: now.weekday);
  late MemoryRoutineRepository routines;
  late MemoryLogRepository logs;
  late _Gateway gateway;
  late RoutineNotificationService notifications;
  late NotificationActionService actions;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await LocalSettingsRepository.instance
        .saveNotificationPreferences(const NotificationPreferences(
      notificationsEnabled: true,
      permissionStatus: NotificationPermissionStatus.granted,
      soundEnabled: true,
    ));
    routines = MemoryRoutineRepository([reading, other]);
    logs = MemoryLogRepository();
    gateway = _Gateway();
    notifications = RoutineNotificationService(
        gateway: gateway, exactAlarmsAllowed: () async => true);
    actions = NotificationActionService(
        routines: routines, logs: logs, notifications: notifications);
  });

  Future<bool> snooze(
          {DateTime? delivery,
          DateTime? at,
          RoutineNotificationTarget? selected}) =>
      actions.snooze(
          target: selected ?? target,
          postedAt: delivery ?? posted,
          now: at ?? now,
          l10n: testL10n);

  test(
      'snooze records the named overlapping routine and schedules once after 15 minutes',
      () async {
    expect(await snooze(), isTrue);
    expect(logs.logs.single.routineId, reading.id);
    expect(logs.logs.single.actionSource, RoutineActionSource.notification);
    expect(logs.logs.single.status, RoutineLogStatus.snoozed);
    expect(gateway.when, now.add(const Duration(minutes: 15)));
    expect(RoutineNotificationTarget.parse(gateway.payload)!.dateYmd,
        '2026-10-04');
    expect(routines.items.first.startMinutesFromMidnight, 9 * 60);
    expect(await snooze(), isFalse); // Duplicate delivery of the same response.
    expect(gateway.schedules, 1);
  });

  test(
      'week-old alert cannot mutate today even when weekday and routine are identical',
      () async {
    expect(await snooze(delivery: posted.subtract(const Duration(days: 7))),
        isFalse);
    expect(logs.logs, isEmpty);
    expect(gateway.schedules, 0);
  });

  test('expired, future, deleted, edited and disabled routines are rejected',
      () async {
    expect(await snooze(at: DateTime(2026, 10, 4, 10)), isFalse);
    expect(
        await snooze(delivery: now.add(const Duration(minutes: 1))), isFalse);
    await routines.deleteRoutine(reading.id);
    expect(await snooze(), isFalse);
    await routines.upsertRoutine(reading.copyWith(updatedAtMs: 999));
    expect(await snooze(), isFalse);
    await routines.upsertRoutine(reading.copyWith(notificationEnabled: false));
    expect(await snooze(), isFalse);
    expect(logs.logs, isEmpty);
  });

  for (final status in [RoutineLogStatus.completed, RoutineLogStatus.skipped]) {
    test('snooze cannot overwrite $status', () async {
      logs.logs.add(RoutineLog(
          id: 'done',
          routineId: reading.id,
          dateYmd: '2026-10-04',
          status: status));
      expect(await snooze(), isFalse);
      expect(logs.logs.single.status, status);
      expect(gateway.schedules, 0);
    });
  }

  test('permission revocation blocks a delivered action', () async {
    await LocalSettingsRepository.instance.saveNotificationPreferences(
        const NotificationPreferences(
            notificationsEnabled: false,
            permissionStatus: NotificationPermissionStatus.denied,
            soundEnabled: true));
    expect(await snooze(), isFalse);
    expect(gateway.schedules, 0);
  });

  test('completion racing scheduling cancels the newly scheduled snooze',
      () async {
    gateway.onSchedule = () async {
      await logs.upsertLog(RoutineLog(
          id: 'done',
          routineId: reading.id,
          dateYmd: '2026-10-04',
          status: RoutineLogStatus.completed));
    };
    await snooze();
    expect(logs.logs.single.status, RoutineLogStatus.completed);
    expect(gateway.cancelled,
        [RoutineNotificationService.snoozeNotificationIdFor(reading.id)]);
  });

  test(
      'completion after lookup rejects the conditional write without scheduling',
      () async {
    final racingLogs = _CompletionBeforeSnoozeRepository();
    actions = NotificationActionService(
      routines: routines,
      logs: racingLogs,
      notifications: notifications,
    );
    expect(await snooze(), isFalse);
    expect(racingLogs.logs.single.status, RoutineLogStatus.completed);
    expect(gateway.schedules, 0);
  });

  test('disabling a routine during scheduling cancels its new snooze',
      () async {
    gateway.onSchedule = () =>
        routines.upsertRoutine(reading.copyWith(notificationEnabled: false));
    await snooze();
    expect(gateway.cancelled,
        [RoutineNotificationService.snoozeNotificationIdFor(reading.id)]);
  });

  test('snooze retains original occurrence when its reminder crosses midnight',
      () async {
    final late = reading.copyWith(
        startMinutesFromMidnight: 23 * 60, endMinutesFromMidnight: 24 * 60);
    routines.items[0] = late;
    final lateTarget =
        RoutineNotificationTarget.forRoutine(late, weekday: now.weekday);
    await snooze(
        selected: lateTarget,
        delivery: DateTime(2026, 10, 4, 23),
        at: DateTime(2026, 10, 4, 23, 55));
    expect(gateway.when, DateTime(2026, 10, 5, 0, 10));
    final nextTarget = RoutineNotificationTarget.parse(gateway.payload)!;
    expect(nextTarget.dateYmd, '2026-10-04');
    expect(
        await snooze(
            selected: nextTarget,
            delivery: gateway.when,
            at: DateTime(2026, 10, 5, 0, 11)),
        isFalse);
  });

  test(
      'confirmation dismisses only the delivered alert, never cancels weekly scheduling',
      () async {
    final nativeCalls = <MethodCall>[];
    final pluginCalls = <MethodCall>[];
    messenger.setMockMethodCallHandler(RoutineNotificationPlatform.channel,
        (call) async {
      nativeCalls.add(call);
      return call.method == 'notificationInfo'
          ? {'postedAt': posted.millisecondsSinceEpoch}
          : null;
    });
    const plugin = MethodChannel('dexterous.com/flutter/local_notifications');
    messenger.setMockMethodCallHandler(plugin, (call) async {
      pluginCalls.add(call);
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(
          RoutineNotificationPlatform.channel, null);
      messenger.setMockMethodCallHandler(plugin, null);
    });
    await NotificationRuntime.instance.handle(NotificationResponse(
        id: 42,
        actionId: notificationAcknowledgeAction,
        payload: target.encode(snooze: false),
        notificationResponseType:
            NotificationResponseType.selectedNotificationAction));
    expect(nativeCalls.map((c) => c.method), ['notificationInfo', 'dismiss']);
    expect(
        nativeCalls.last.arguments['postedAt'], posted.millisecondsSinceEpoch);
    expect(pluginCalls, isEmpty);
    expect(logs.logs, isEmpty);
  });

  test('body tap preserves original routine and delivery date for navigation',
      () async {
    final old = posted.subtract(const Duration(days: 7));
    messenger.setMockMethodCallHandler(
        RoutineNotificationPlatform.channel,
        (call) async => call.method == 'notificationInfo'
            ? {'postedAt': old.millisecondsSinceEpoch}
            : null);
    addTearDown(() {
      messenger.setMockMethodCallHandler(
          RoutineNotificationPlatform.channel, null);
      NotificationRuntime.instance.openRequest.value = null;
    });
    await NotificationRuntime.instance.handle(NotificationResponse(
        id: 42,
        payload: target.encode(snooze: false),
        notificationResponseType:
            NotificationResponseType.selectedNotification));
    expect(NotificationRuntime.instance.openRequest.value!.target.routineId,
        reading.id);
    expect(
        NotificationRuntime.instance.openRequest.value!.dateYmd, '2026-09-27');
  });

  test(
      'notification screen completion targets the named routine instead of current overlap winner',
      () async {
    messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'), (_) async => true);
    addTearDown(() => messenger.setMockMethodCallHandler(
        const MethodChannel('home_widget'), null));
    final app = RoutineAppController(
        dataService: RoutineDataService(
            routineRepository: routines, logRepository: logs),
        notificationService: notifications,
        completionHaptic: () async {},
        nowProvider: () => now,
        clockAutoRefreshEnabled: false);
    addTearDown(app.dispose);
    await app.load();
    expect(app.currentRoutine!.id, other.id);
    expect(await app.completeNotificationRoutine(reading.id, '2026-09-27'),
        isNull);
    await app.completeNotificationRoutine(reading.id, '2026-10-04');
    expect(logs.logs.single.routineId, reading.id);
    expect(logs.logs.single.status, RoutineLogStatus.completed);
    expect(await app.completeNotificationRoutine(reading.id, '2026-10-04'),
        isNull);
  });

  test('legacy payloads remain navigable, malformed payloads are ignored', () {
    expect(
        RoutineNotificationTarget.parse('routine_notification:legacy:2')!
            .routineId,
        'legacy');
    expect(RoutineNotificationTarget.parse('routine_snooze:legacy')!.routineId,
        'legacy');
    expect(RoutineNotificationTarget.parse('routine_preview'), isNull);
    expect(RoutineNotificationTarget.parse('routine_notification:{invalid'),
        isNull);
  });
}

class _CompletionBeforeSnoozeRepository extends MemoryLogRepository {
  @override
  Future<bool> saveNotificationSnooze(RoutineLog log) async {
    await upsertLog(log.copyWith(status: RoutineLogStatus.completed));
    return super.saveNotificationSnooze(log);
  }
}

class _Gateway extends NoopNotificationGateway {
  int schedules = 0;
  DateTime? when;
  String? payload;
  final cancelled = <int>[];
  Future<void> Function()? onSchedule;
  @override
  Future<void> cancel(int id) async => cancelled.add(id);
  @override
  Future<void> scheduleOnce(
      {required int id,
      required String title,
      required String body,
      required DateTime whenLocal,
      required NotificationDetails details,
      required String payload,
      required bool exact}) async {
    schedules++;
    when = whenLocal;
    this.payload = payload;
    await onSchedule?.call();
  }
}
