import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/data/local/local_routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

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
        routineRepository: _FakeRoutineRepository([
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
    final routineRepository = _FakeRoutineRepository([
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
}

class _FakeRoutineRepository implements RoutineRepository {
  _FakeRoutineRepository(this._items);

  final List<Routine> _items;

  @override
  Future<void> addRoutine(Routine routine) async {
    _items.add(routine);
  }

  @override
  Future<List<Routine>> loadRoutines() async {
    return List<Routine>.from(_items);
  }

  @override
  Future<void> deleteRoutine(String routineId) async {
    _items.removeWhere((item) => item.id == routineId);
  }

  @override
  Future<void> saveRoutines(List<Routine> routines) async {
    _items
      ..clear()
      ..addAll(routines);
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    final index = _items.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      _items.add(routine);
    } else {
      _items[index] = routine;
    }
  }
}

class _FakeRoutineLogRepository implements RoutineLogRepository {
  _FakeRoutineLogRepository(this._logsByDate);

  final Map<String, List<RoutineLog>> _logsByDate;

  @override
  Future<List<RoutineLog>> loadAllLogs() async {
    return _logsByDate.values.expand((logs) => logs).toList();
  }

  @override
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal) async {
    final key =
        '${dateLocal.year.toString().padLeft(4, '0')}-${dateLocal.month.toString().padLeft(2, '0')}-${dateLocal.day.toString().padLeft(2, '0')}';
    return List<RoutineLog>.from(_logsByDate[key] ?? const []);
  }

  @override
  Future<void> upsertLog(RoutineLog log) async {
    final list = _logsByDate.putIfAbsent(log.dateYmd, () => <RoutineLog>[]);
    final index = list.indexWhere(
      (item) =>
          item.id == log.id ||
          (item.routineId == log.routineId && item.dateYmd == log.dateYmd),
    );
    if (index == -1) {
      list.add(log);
    } else {
      list[index] = log;
    }
  }

  @override
  Future<void> deleteLogsForRoutine(String routineId) async {
    for (final logs in _logsByDate.values) {
      logs.removeWhere((log) => log.routineId == routineId);
    }
  }
}
