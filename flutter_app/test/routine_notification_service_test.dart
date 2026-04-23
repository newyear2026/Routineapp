import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';

void main() {
  test('syncAll cancels existing managed notifications and reschedules enabled routines', () async {
    final gateway = _FakeLocalNotificationGateway(
      pending: [
        const PendingNotificationRequest(
          10,
          'old',
          'old',
          'routine_notification:legacy:1',
        ),
        const PendingNotificationRequest(11, 'keep', 'keep', 'foreign'),
      ],
    );
    final service = RoutineNotificationService(
      gateway: gateway,
      preferencesLoader: () async => const NotificationPreferences(
        notificationsEnabled: true,
        permissionStatus: NotificationPermissionStatus.granted,
        soundEnabled: true,
      ),
    );

    const routine = Routine(
      id: 'routine_1',
      title: '아침 산책',
      startMinutesFromMidnight: 7 * 60,
      endMinutesFromMidnight: 8 * 60,
      repeatWeekdays: {1, 3},
      colorValue: 0xFF000000,
      iconEmoji: '📌',
      notificationEnabled: true,
    );

    await service.syncAll([routine]);

    expect(gateway.cancelledIds, [10]);
    expect(gateway.scheduled.map((item) => item.id), [
      RoutineNotificationService.notificationIdFor('routine_1', 1),
      RoutineNotificationService.notificationIdFor('routine_1', 3),
    ]);
  });

  test('syncAll skips scheduling when app notifications are disabled', () async {
    final gateway = _FakeLocalNotificationGateway();
    final service = RoutineNotificationService(
      gateway: gateway,
      preferencesLoader: () async => const NotificationPreferences(
        notificationsEnabled: false,
        permissionStatus: NotificationPermissionStatus.granted,
        soundEnabled: true,
      ),
    );

    const routine = Routine(
      id: 'routine_1',
      title: '저녁 독서',
      startMinutesFromMidnight: 21 * 60,
      endMinutesFromMidnight: 22 * 60,
      repeatWeekdays: {2, 4},
      colorValue: 0xFF000000,
      iconEmoji: '📌',
      notificationEnabled: true,
    );

    await service.syncAll([routine]);

    expect(gateway.scheduled, isEmpty);
  });
}

class _FakeLocalNotificationGateway implements LocalNotificationGateway {
  _FakeLocalNotificationGateway({
    List<PendingNotificationRequest>? pending,
  }) : _pending = List<PendingNotificationRequest>.from(pending ?? const []);

  final List<PendingNotificationRequest> _pending;
  final List<int> cancelledIds = [];
  final List<_ScheduledNotification> scheduled = [];
  bool initialized = false;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> cancel(int id) async {
    cancelledIds.add(id);
  }

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    return List<PendingNotificationRequest>.from(_pending);
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
    scheduled.add(
      _ScheduledNotification(
        id: id,
        weekday: weekday,
        time: time,
        payload: payload,
      ),
    );
  }
}

class _ScheduledNotification {
  const _ScheduledNotification({
    required this.id,
    required this.weekday,
    required this.time,
    required this.payload,
  });

  final int id;
  final int weekday;
  final TimeOfDay time;
  final String payload;
}
