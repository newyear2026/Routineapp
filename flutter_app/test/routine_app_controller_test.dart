import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/local/local_routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/settings/notification_permission_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/models/routine_write_error.dart';
import 'support/localization.dart';
import 'support/test_doubles.dart';
import 'support/routine_test_harness.dart';

void main() {
  setUpRoutineTestEnvironment();

  test('local log repository upserts by routine/date even when id differs',
      () async {
    final repository = LocalRoutineLogRepository.instance;

    await repository.upsertLog(
      const RoutineLog(
        id: 'log_a',
        routineId: 'routine_1',
        dateYmd: '2026-04-09',
        status: RoutineLogStatus.snoozed,
      ),
    );
    await repository.upsertLog(
      const RoutineLog(
        id: 'log_b',
        routineId: 'routine_1',
        dateYmd: '2026-04-09',
        status: RoutineLogStatus.completed,
      ),
    );

    final logs = await repository.loadAllLogs();

    expect(logs, hasLength(1));
    expect(logs.single.id, 'log_b');
    expect(logs.single.status, RoutineLogStatus.completed);
  });

  test('controller reloads today logs when date rolls over', () async {
    var now = DateTime(2026, 4, 9, 23, 59);
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          Routine(
            id: 'routine_1',
            title: '야간 루틴',
            startMinutesFromMidnight: 23 * 60,
            endMinutesFromMidnight: 24 * 60 - 1,
            repeatWeekdays: const {4, 5},
            colorValue: const Color(0xFFE91E63).toARGB32(),
            iconEmoji: '🌙',
          ),
        ]),
        logRepository: _FakeRoutineLogRepository({
          '2026-04-09': const [
            RoutineLog(
              id: 'routine_1_2026-04-09',
              routineId: 'routine_1',
              dateYmd: '2026-04-09',
              status: RoutineLogStatus.completed,
            ),
          ],
          '2026-04-10': const [
            RoutineLog(
              id: 'routine_1_2026-04-10',
              routineId: 'routine_1',
              dateYmd: '2026-04-10',
              status: RoutineLogStatus.scheduled,
            ),
          ],
        }),
      ),
      notificationService: _testNotificationService(),
      nowProvider: () => now,
      clockAutoRefreshEnabled: false,
    );

    await controller.load();
    expect(controller.todayLogs.single.dateYmd, '2026-04-09');

    now = DateTime(2026, 4, 10, 0, 0);
    await controller.refreshClockStateForTest();

    expect(controller.todayLogs.single.dateYmd, '2026-04-10');

    controller.dispose();
  });

  test('controller deletes routine and associated logs together', () async {
    final routineRepository = MemoryRoutineRepository([
      Routine(
        id: 'routine_1',
        title: '아침 루틴',
        startMinutesFromMidnight: 8 * 60,
        endMinutesFromMidnight: 9 * 60,
        repeatWeekdays: const {4},
        colorValue: const Color(0xFFE91E63).toARGB32(),
        iconEmoji: '🌤️',
      ),
      Routine(
        id: 'routine_2',
        title: '점심 루틴',
        startMinutesFromMidnight: 12 * 60,
        endMinutesFromMidnight: 13 * 60,
        repeatWeekdays: const {4},
        colorValue: const Color(0xFF42A5F5).toARGB32(),
        iconEmoji: '🍽️',
      ),
    ]);
    final logRepository = _FakeRoutineLogRepository({
      '2026-04-09': [
        const RoutineLog(
          id: 'routine_1_2026-04-09',
          routineId: 'routine_1',
          dateYmd: '2026-04-09',
          status: RoutineLogStatus.completed,
        ),
        const RoutineLog(
          id: 'routine_2_2026-04-09',
          routineId: 'routine_2',
          dateYmd: '2026-04-09',
          status: RoutineLogStatus.scheduled,
        ),
      ],
    });
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: routineRepository,
        logRepository: logRepository,
      ),
      notificationService: _testNotificationService(),
      nowProvider: () => DateTime(2026, 4, 9, 8, 30),
      clockAutoRefreshEnabled: false,
    );

    await controller.load();
    final result = await controller.deleteRoutine('routine_1');

    expect(result.ok, isTrue);
    expect(controller.routines.map((routine) => routine.id), ['routine_2']);
    expect(
      controller.todayLogs.map((log) => log.routineId),
      ['routine_2'],
    );

    controller.dispose();
  });

  test('controller CRUD updates home snapshot segments for circular timetable',
      () async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([]),
        logRepository: _FakeRoutineLogRepository({}),
      ),
      notificationService: _testNotificationService(),
      nowProvider: () => DateTime(2026, 4, 9, 8, 30),
      clockAutoRefreshEnabled: false,
    );

    await controller.load();
    expect(controller.homeSnapshotFor(testL10n).segments, isEmpty);
    expect(controller.homeSnapshotFor(testL10n).isEmptyDay, isTrue);

    const added = Routine(
      id: 'routine_1',
      title: '아침 산책',
      startMinutesFromMidnight: 8 * 60,
      endMinutesFromMidnight: 9 * 60,
      repeatWeekdays: {4},
      colorValue: 0xFFE91E63,
      iconEmoji: '🚶',
    );

    final addResult = await controller.saveRoutine(added);

    expect(addResult.ok, isTrue);
    expect(controller.homeSnapshotFor(testL10n).segments, hasLength(1));
    expect(controller.homeSnapshotFor(testL10n).isEmptyDay, isFalse);
    expect(
        controller.homeSnapshotFor(testL10n).segments.single.id, 'routine_1');
    expect(controller.homeSnapshotFor(testL10n).segments.single.label, '아침 산책');
    expect(
      controller
          .homeSnapshotFor(testL10n)
          .segments
          .single
          .startMinutesFromMidnight,
      8 * 60,
    );
    expect(
      controller
          .homeSnapshotFor(testL10n)
          .segments
          .single
          .endMinutesFromMidnight,
      9 * 60,
    );

    const updated = Routine(
      id: 'routine_1',
      title: '아침 독서',
      startMinutesFromMidnight: 10 * 60,
      endMinutesFromMidnight: 11 * 60,
      repeatWeekdays: {4},
      colorValue: 0xFF42A5F5,
      iconEmoji: '📚',
    );

    final updateResult = await controller.saveRoutine(updated);

    expect(updateResult.ok, isTrue);
    expect(controller.homeSnapshotFor(testL10n).segments, hasLength(1));
    expect(
        controller.homeSnapshotFor(testL10n).segments.single.id, 'routine_1');
    expect(controller.homeSnapshotFor(testL10n).segments.single.label, '아침 독서');
    expect(
      controller
          .homeSnapshotFor(testL10n)
          .segments
          .single
          .startMinutesFromMidnight,
      10 * 60,
    );
    expect(
      controller
          .homeSnapshotFor(testL10n)
          .segments
          .single
          .endMinutesFromMidnight,
      11 * 60,
    );

    final deleteResult = await controller.deleteRoutine('routine_1');

    expect(deleteResult.ok, isTrue);
    expect(controller.homeSnapshotFor(testL10n).segments, isEmpty);
    expect(controller.homeSnapshotFor(testL10n).isEmptyDay, isTrue);

    controller.dispose();
  });

  test('알림 동기화가 실패해도 저장은 성공으로 답한다', () async {
    // 릴리즈 빌드에서 flutter_local_notifications가
    // PlatformException(Missing type parameter.)를 던졌다. 예전에는 이 예외가
    // saveRoutine의 catch까지 올라가 "저장에 실패했어요"가 떴고, 실제로는
    // 이미 저장된 뒤라 사용자가 다시 눌러 같은 루틴이 여러 개 생겼다.
    final repository = MemoryRoutineRepository([]);
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: repository,
        logRepository: _FakeRoutineLogRepository({}),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: _ThrowingNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 6, 9, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();

    final result = await controller.saveRoutine(
      Routine.create(
        title: '아침 산책',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        repeatWeekdays: const {DateTime.thursday},
        colorValue: 0xFF6C4CF1,
      ),
    );

    expect(result.ok, isTrue, reason: result.error?.name);
    expect(result.error, isNull);
    expect(controller.routines.map((r) => r.title), ['아침 산책']);
    controller.dispose();
  });

  test('저장소 쓰기가 실패할 때만 실패로 답한다', () async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: _FailingRoutineRepository(),
        logRepository: _FakeRoutineLogRepository({}),
      ),
      notificationService: _testNotificationService(),
      nowProvider: () => DateTime(2026, 8, 6, 9, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();

    final result = await controller.saveRoutine(
      Routine.create(
        title: '아침 산책',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        repeatWeekdays: const {DateTime.thursday},
        colorValue: 0xFF6C4CF1,
      ),
    );

    expect(result.ok, isFalse);
    expect(result.error, RoutineWriteError.save);
    controller.dispose();
  });

  test('홈 위젯 갱신이 실패해도 완료 기록과 되돌리기는 살아남는다', () async {
    // 위젯 갱신은 부수 효과다. 기록은 이미 저장소에 들어간 뒤라, 여기서
    // 터졌다고 홈의 성공 안내와 되돌리기 버튼까지 사라지면 안 된다.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('home_widget'),
      (call) async => throw PlatformException(code: 'unavailable'),
    );

    final now = DateTime(2026, 4, 9, 7, 30);
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          Routine(
            id: 'routine_1',
            title: '기상',
            startMinutesFromMidnight: 7 * 60,
            endMinutesFromMidnight: 8 * 60,
            repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
            colorValue: const Color(0xFF6C4CF1).toARGB32(),
            iconEmoji: '🌅',
          ),
        ]),
        logRepository: _FakeRoutineLogRepository({}),
      ),
      notificationService: _testNotificationService(),
      nowProvider: () => now,
      clockAutoRefreshEnabled: false,
    );
    addTearDown(controller.dispose);

    await controller.load();

    final undo = await controller.completeCurrent();

    expect(undo, isNotNull);
    expect(controller.todayLogs.single.status, RoutineLogStatus.completed);

    await controller.undoAction(undo!);

    expect(controller.todayLogs, isEmpty);
  });
}

class _FakeRoutineLogRepository extends MemoryLogRepository {
  _FakeRoutineLogRepository(Map<String, List<RoutineLog>> logsByDate)
      : super(logsByDate.values.expand((logs) => logs));
}

RoutineNotificationService _testNotificationService() {
  return RoutineNotificationService(
    exactAlarmsAllowed: () async => false,
    gateway: NoopNotificationGateway(),
    preferencesLoader: () async => const NotificationPreferences(
      notificationsEnabled: false,
      permissionStatus: NotificationPermissionStatus.notRequested,
      soundEnabled: false,
    ),
  );
}

class _ThrowingNotificationGateway implements LocalNotificationGateway {
  @override
  Future<void> show(
      {required int id,
      required String title,
      required String body,
      required NotificationDetails details}) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> cancel(int id) async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    throw PlatformException(code: 'error', message: 'Missing type parameter.');
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
  }) async {}

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

class _FailingRoutineRepository implements RoutineRepository {
  @override
  Future<void> addRoutine(Routine routine) async =>
      throw Exception('disk full');

  @override
  Future<void> deleteRoutine(String routineId) async =>
      throw Exception('disk full');

  @override
  Future<List<Routine>> loadRoutines() async => const [];

  @override
  Future<void> saveRoutines(List<Routine> routines) async =>
      throw Exception('disk full');

  @override
  Future<void> upsertRoutine(Routine routine) async =>
      throw Exception('disk full');
}
