import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/settings/settings_controller.dart';
import 'package:routine_timer/data/local/local_settings_repository.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final repository = LocalSettingsRepository.instance;
  final routine =
      dailyRoutine(id: 'reading', title: '독서', startHour: 9, endHour: 10);
  final now = DateTime(2026, 10, 1, 9, 10);
  const initial = NotificationPreferences(
      notificationsEnabled: true,
      permissionStatus: NotificationPermissionStatus.granted,
      soundEnabled: true);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'legacy sound-off preferences migrate to vibration-only and persist all modes',
      () async {
    SharedPreferences.setMockInitialValues({
      'prefs.notifications.enabled': true,
      'prefs.notifications.permission_status': 'granted',
      'prefs.notifications.sound_enabled': false,
    });
    expect((await repository.loadNotificationPreferences()).mode,
        RoutineNotificationMode.vibrationOnly);
    for (final mode in RoutineNotificationMode.values) {
      await repository.saveNotificationPreferences(initial.copyWith(
        soundEnabled: mode == RoutineNotificationMode.soundAndVibration,
        vibrationEnabled: mode != RoutineNotificationMode.visualOnly,
        completionHapticEnabled: false,
      ));
      final saved = await repository.loadNotificationPreferences();
      expect(saved.mode, mode);
      expect(saved.completionHapticEnabled, isFalse);
    }
  });

  test(
      'each mode has a separate stable channel and correct sound/vibration flags',
      () async {
    final gateway = _Gateway();
    final service = RoutineNotificationService(
        gateway: gateway,
        preferencesLoader: repository.loadNotificationPreferences,
        exactAlarmsAllowed: () async => false);
    final channelIds = <String>{};
    for (final mode in RoutineNotificationMode.values) {
      await repository.saveNotificationPreferences(initial.copyWith(
          soundEnabled: mode == RoutineNotificationMode.soundAndVibration,
          vibrationEnabled: mode != RoutineNotificationMode.visualOnly));
      await service.syncAll([routine], testL10n);
      final details = gateway.weekly.last;
      expect(details.android!.playSound,
          mode == RoutineNotificationMode.soundAndVibration);
      expect(details.android!.enableVibration,
          mode != RoutineNotificationMode.visualOnly);
      expect(details.iOS!.presentSound,
          mode == RoutineNotificationMode.soundAndVibration);
      channelIds.add(details.android!.channelId);
      await service.showPreview(testL10n);
      expect(gateway.shown.last.android!.channelId, details.android!.channelId);
    }
    expect(channelIds, hasLength(3));
    expect(gateway.shown, hasLength(3));
  });

  test(
      'turning notifications off and on retains visual-only and completion preferences',
      () async {
    await repository.saveNotificationPreferences(initial.copyWith(
        soundEnabled: false,
        vibrationEnabled: false,
        completionHapticEnabled: false));
    final controller = SettingsController(
        repository: repository,
        logRepository: MemoryLogRepository(),
        requestPermission: () async => true,
        notificationService: RoutineNotificationService(
            gateway: _Gateway(),
            preferencesLoader: repository.loadNotificationPreferences,
            exactAlarmsAllowed: () async => false));
    addTearDown(controller.dispose);
    await controller.load();
    await controller.setNotificationsEnabled(false, [routine], testL10n);
    await controller.setNotificationsEnabled(true, [routine], testL10n);
    expect(controller.notificationMode, RoutineNotificationMode.visualOnly);
    expect(controller.completionHapticEnabled, isFalse);
    expect((await repository.loadNotificationPreferences()).mode,
        RoutineNotificationMode.visualOnly);
  });

  test(
      'mode change updates an existing snooze at the same time, without reviving delivered snoozes',
      () async {
    final gateway = _Gateway();
    final until = DateTime.now().add(const Duration(minutes: 15));
    final log = RoutineLog(
        id: 'reading:today',
        routineId: routine.id,
        dateYmd: '2026-10-01',
        status: RoutineLogStatus.snoozed,
        snoozedUntilMs: until.millisecondsSinceEpoch);
    final logs = MemoryLogRepository()..logs.add(log);
    final service = RoutineNotificationService(
        gateway: gateway,
        preferencesLoader: repository.loadNotificationPreferences,
        exactAlarmsAllowed: () async => false);
    await repository.saveNotificationPreferences(initial);
    await service.scheduleSnooze(routine, until, testL10n);
    final controller = SettingsController(
        repository: repository,
        logRepository: logs,
        notificationService: service);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.setNotificationMode(
        RoutineNotificationMode.visualOnly, [routine], testL10n);
    expect(gateway.onceTimes.last.millisecondsSinceEpoch,
        until.millisecondsSinceEpoch);
    expect(gateway.onceDetails.last.android!.playSound, isFalse);
    expect(gateway.onceDetails.last.android!.enableVibration, isFalse);
    gateway.pending.clear();
    final scheduled = gateway.onceTimes.length;
    await controller.setNotificationMode(
        RoutineNotificationMode.vibrationOnly, [routine], testL10n);
    expect(gateway.onceTimes, hasLength(scheduled));
  });

  test('preview does not post when permission is denied', () async {
    await repository.saveNotificationPreferences(initial);
    final gateway = _Gateway();
    final controller = SettingsController(
        repository: repository,
        requestPermission: () async => false,
        notificationService: RoutineNotificationService(
            gateway: gateway,
            preferencesLoader: repository.loadNotificationPreferences));
    addTearDown(controller.dispose);
    await controller.load();
    expect(await controller.previewNotification(testL10n), isFalse);
    expect(gateway.shown, isEmpty);
    expect(controller.isUpdating, isFalse);
  });

  for (final enabled in [true, false]) {
    test(
        'completion haptic follows preference ($enabled) even when notifications are off',
        () async {
      await repository.saveNotificationPreferences(initial.copyWith(
          notificationsEnabled: false, completionHapticEnabled: enabled));
      var haptics = 0;
      final app = RoutineAppController(
          dataService: RoutineDataService(
              routineRepository: MemoryRoutineRepository([routine]),
              logRepository: MemoryLogRepository()),
          settingsRepository: repository,
          notificationService: RoutineNotificationService(
              gateway: NoopNotificationGateway(),
              preferencesLoader: repository.loadNotificationPreferences),
          completionHaptic: () async {
            haptics++;
          },
          nowProvider: () => now,
          clockAutoRefreshEnabled: false);
      addTearDown(app.dispose);
      await app.load();
      await app.completeCurrent();
      await app.completeCurrent();
      expect(haptics, enabled ? 1 : 0);
    });
  }

  test('failed completion save never produces a success haptic', () async {
    await repository.saveNotificationPreferences(initial);
    var haptics = 0;
    final app = RoutineAppController(
        dataService: RoutineDataService(
            routineRepository: MemoryRoutineRepository([routine]),
            logRepository: _FailingLogs()),
        notificationService: RoutineNotificationService(
            gateway: NoopNotificationGateway(),
            preferencesLoader: () async =>
                NotificationPreferences.firstLaunchDefaults),
        completionHaptic: () async {
          haptics++;
        },
        nowProvider: () => now,
        clockAutoRefreshEnabled: false);
    addTearDown(app.dispose);
    await app.load();
    await expectLater(app.completeCurrent(), throwsStateError);
    expect(haptics, 0);
  });
}

class _FailingLogs extends MemoryLogRepository {
  @override
  Future<void> upsertLog(RoutineLog log) async =>
      throw StateError('storage failed');
}

class _Gateway extends NoopNotificationGateway {
  final weekly = <NotificationDetails>[];
  final onceDetails = <NotificationDetails>[];
  final onceTimes = <DateTime>[];
  final shown = <NotificationDetails>[];
  final pending = <PendingNotificationRequest>[];

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => List.of(pending);
  @override
  Future<void> cancel(int id) async => pending.removeWhere((p) => p.id == id);
  @override
  Future<void> show(
          {required int id,
          required String title,
          required String body,
          required NotificationDetails details}) async =>
      shown.add(details);
  @override
  Future<void> scheduleWeekly(
          {required int id,
          required String title,
          required String body,
          required int weekday,
          required TimeOfDay time,
          required NotificationDetails details,
          required String payload,
          required bool exact}) async =>
      weekly.add(details);
  @override
  Future<void> scheduleOnce(
      {required int id,
      required String title,
      required String body,
      required DateTime whenLocal,
      required NotificationDetails details,
      required String payload,
      required bool exact}) async {
    pending.removeWhere((p) => p.id == id);
    pending.add(PendingNotificationRequest(id, title, body, payload));
    onceDetails.add(details);
    onceTimes.add(whenLocal);
  }
}
