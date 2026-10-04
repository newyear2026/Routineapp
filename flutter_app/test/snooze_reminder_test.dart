import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');
  final now = DateTime(2026, 4, 9, 7, 30);
  final snoozeId = RoutineNotificationService.snoozeNotificationIdFor('wake');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  Future<RoutineAppController> loadedController(
    LocalNotificationGateway gateway,
  ) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: gateway,
        preferencesLoader: () async => const NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: true,
        ),
      ),
      nowProvider: () => now,
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    return controller;
  }

  group('«나중에» 재알림 배선', () {
    test('미루면 15분 뒤로 재알림을 건다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);

      await controller.snoozeCurrent();

      expect(gateway.scheduledOnce, hasLength(1));
      final once = gateway.scheduledOnce.single;
      expect(once.id, snoozeId);
      expect(once.whenLocal, now.add(const Duration(minutes: 15)));
      expect(once.title, '기상');
    });

    test('완료하면 걸어둔 재알림을 거둔다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);

      await controller.snoozeCurrent();
      gateway.cancelledIds.clear();

      await controller.completeCurrent();

      expect(gateway.cancelledIds, contains(snoozeId));
    });

    test('건너뛰면 걸어둔 재알림을 거둔다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);

      await controller.snoozeCurrent();
      gateway.cancelledIds.clear();

      await controller.skipCurrent();

      expect(gateway.cancelledIds, contains(snoozeId));
    });

    test('미루기를 되돌리면 재알림도 거둔다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);

      final undo = await controller.snoozeCurrent();
      gateway.cancelledIds.clear();

      await controller.undoAction(undo!);

      expect(gateway.cancelledIds, contains(snoozeId));
    });

    test('완료를 되돌려 미룬 상태로 돌아가면 재알림을 다시 건다', () async {
      final gateway = RecordingNotificationGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);

      await controller.snoozeCurrent();
      final undo = await controller.completeCurrent();
      gateway.scheduledOnce.clear();

      await controller.undoAction(undo!);

      expect(gateway.scheduledOnce, hasLength(1));
      expect(gateway.scheduledOnce.single.id, snoozeId);
    });

    test('재알림 예약이 실패해도 미룬 기록은 남는다', () async {
      // 알림은 부수 효과다. 여기서 터졌다고 기록과 되돌리기까지 잃으면
      // 안 된다 — 홈 위젯 갱신과 같은 규칙이다.
      final controller = await loadedController(_SnoozeFailingGateway());
      addTearDown(controller.dispose);

      final undo = await controller.snoozeCurrent();

      expect(undo, isNotNull);
      expect(controller.todayLogs.single.snoozedUntilMs, isNotNull);
    });

    for (final delete in [true, false]) {
      test(delete ? '미룬 루틴을 삭제하면 재알림도 취소한다' : '미룬 루틴의 개별 알림을 끄면 재알림도 취소한다',
          () async {
        final gateway = _PendingSnoozeGateway();
        final controller = await loadedController(gateway);
        addTearDown(controller.dispose);
        await controller.snoozeCurrent();
        expect(await gateway.pendingNotificationRequests(), hasLength(1));

        if (delete) {
          await controller.deleteRoutine('wake');
        } else {
          await controller.saveRoutine(
              controller.routines.single.copyWith(notificationEnabled: false));
        }
        expect(await gateway.pendingNotificationRequests(), isEmpty);
      });
    }

    test('다른 루틴을 저장해도 원래 미룬 재알림은 남긴다', () async {
      final gateway = _PendingSnoozeGateway();
      final controller = await loadedController(gateway);
      addTearDown(controller.dispose);
      await controller.snoozeCurrent();
      final reminder = gateway.scheduledOnce.single;
      await controller.saveRoutine(
          dailyRoutine(id: 'reading', title: '독서', startHour: 9, endHour: 10));
      expect(await gateway.pendingNotificationRequests(), hasLength(1));
      expect(gateway.cancelledIds, isNot(contains(reminder.id)));
      expect(gateway.scheduledOnce, [reminder]);
    });
  });
}

class _PendingSnoozeGateway extends RecordingNotificationGateway {
  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => [
            for (final reminder in scheduledOnce)
              if (!cancelledIds.contains(reminder.id))
                PendingNotificationRequest(reminder.id, reminder.title,
                    reminder.body, reminder.payload),
          ];
}

/// 1회성 예약만 실패하는 게이트웨이. 나머지는 정상이라 로드는 통과한다.
class _SnoozeFailingGateway extends RecordingNotificationGateway {
  @override
  Future<void> scheduleOnce({
    required int id,
    required String title,
    required String body,
    required DateTime whenLocal,
    required NotificationDetails details,
    required String payload,
    required bool exact,
  }) async =>
      throw PlatformException(code: 'unavailable');
}
