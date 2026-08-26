import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'support/localization.dart';

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
      exactAlarmsAllowed: () async => false,
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

    await service.syncAll([routine], testL10n);

    expect(gateway.cancelledIds, [10]);
    expect(gateway.scheduled.map((item) => item.id), [
      RoutineNotificationService.notificationIdFor('routine_1', 1),
      RoutineNotificationService.notificationIdFor('routine_1', 3),
    ]);
  });

  test('syncAll skips scheduling when app notifications are disabled', () async {
    final gateway = _FakeLocalNotificationGateway();
    final service = RoutineNotificationService(
      exactAlarmsAllowed: () async => false,
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

    await service.syncAll([routine], testL10n);

    expect(gateway.scheduled, isEmpty);
  });

  test('소리 설정에 따라 알림 채널이 갈린다', () async {
    // Android 8.0+ 는 채널을 만든 시점의 소리 설정을 굳힌다. 같은 채널에
    // playSound 만 바꿔 걸면 조용히 무시되므로, 설정이 채널을 가르는지 본다.
    Future<AndroidNotificationDetails> scheduleWith(bool soundEnabled) async {
      final gateway = _FakeLocalNotificationGateway();
      final service = RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: gateway,
        preferencesLoader: () async => NotificationPreferences(
          notificationsEnabled: true,
          permissionStatus: NotificationPermissionStatus.granted,
          soundEnabled: soundEnabled,
        ),
      );

      const routine = Routine(
        id: 'routine_1',
        title: '아침 산책',
        startMinutesFromMidnight: 7 * 60,
        endMinutesFromMidnight: 8 * 60,
        repeatWeekdays: {1},
        colorValue: 0xFF000000,
        iconEmoji: '📌',
        notificationEnabled: true,
      );

      await service.syncAll([routine], testL10n);
      return gateway.scheduled.single.details.android!;
    }

    final withSound = await scheduleWith(true);
    final silent = await scheduleWith(false);

    expect(withSound.channelId, RoutineNotificationService.soundChannelId);
    expect(withSound.playSound, isTrue);

    expect(silent.channelId, RoutineNotificationService.silentChannelId);
    expect(silent.playSound, isFalse);

    // 두 채널이 시스템 설정에서 구분되도록 이름도 달라야 한다.
    expect(withSound.channelName, isNot(silent.channelName));

    // 무음이어도 진동은 남긴다.
    expect(silent.enableVibration, isTrue);
  });

  test('정확 알람 권한이 있으면 정확 모드로, 없으면 부정확으로 예약한다', () async {
    // 권한 없이 exact 로 걸면 Android 12+ 가 SecurityException 을 던져 예약이
    // 통째로 실패한다. 권한 상태가 예약 모드로 그대로 이어지는지 본다.
    Future<bool> scheduleWith(bool allowed) async {
      final gateway = _FakeLocalNotificationGateway();
      final service = RoutineNotificationService(
        gateway: gateway,
        exactAlarmsAllowed: () async => allowed,
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
        repeatWeekdays: {1},
        colorValue: 0xFF000000,
        iconEmoji: '📌',
        notificationEnabled: true,
      );

      await service.syncAll([routine], testL10n);
      return gateway.scheduled.single.exact;
    }

    expect(await scheduleWith(true), isTrue);
    expect(await scheduleWith(false), isFalse);
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
    required bool exact,
  }) async {
    scheduled.add(
      _ScheduledNotification(
        id: id,
        weekday: weekday,
        time: time,
        payload: payload,
        details: details,
        exact: exact,
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
    required this.details,
    required this.exact,
  });

  final int id;
  final int weekday;
  final TimeOfDay time;
  final String payload;
  final NotificationDetails details;
  final bool exact;
}
