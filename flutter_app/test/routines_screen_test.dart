import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 목록·캘린더 전환 칸이 트랙 높이를 다 쓰는지 확인한다.
///
/// Row에 stretch가 없으면 각 칸이 내용 높이(약 19)로만 잡혀, 선택된 흰 pill이
/// 가운데 떠 보이고 트랙 위아래 절반이 눌리지 않았다.
void _expectSwitchFillsTrack(WidgetTester tester) {
  for (final label in ['목록', '캘린더']) {
    final size = tester.getSize(find.byKey(Key('routine-view-$label')));
    expect(
      size.height,
      greaterThanOrEqualTo(44),
      reason: '$label 칸 높이 ${size.height} — 터치 타깃 44 미만',
    );
  }
  // 두 칸은 같은 폭이어야 한다.
  expect(
    tester.getSize(find.byKey(const Key('routine-view-목록'))).width,
    tester.getSize(find.byKey(const Key('routine-view-캘린더'))).width,
  );
}

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

  testWidgets('calendar view selects a day and projects its repeated routines',
      (tester) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: _MemoryRoutineRepository([
          const Routine(
            id: 'thursday_walk',
            title: '아침 산책',
            startMinutesFromMidnight: 8 * 60,
            endMinutesFromMidnight: 9 * 60,
            repeatWeekdays: {DateTime.thursday},
            colorValue: 0xFF6C4CF1,
            iconEmoji: '🚶',
          ),
        ]),
        logRepository: _MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: _NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 6, 8, 30),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: RoutinesScreen()),
      ),
    );

    expect(find.text('아침 산책'), findsOneWidget);
    _expectSwitchFillsTrack(tester);

    // 트랙 맨 윗줄을 눌러도 전환돼야 한다 (예전에는 가운데만 눌렸다).
    final calendarTab = find.byKey(const Key('routine-view-캘린더'));
    final box = tester.getRect(calendarTab);
    await tester.tapAt(Offset(box.center.dx, box.top + 3));
    await tester.pumpAndSettle();

    expect(find.text('8월 6일 · 목요일'), findsOneWidget);
    expect(find.text('아침 산책'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-day-2026-8-7')));
    await tester.pumpAndSettle();

    expect(find.text('8월 7일 · 금요일'), findsOneWidget);
    expect(find.text('예정된 루틴이 없어요'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('calendar weekday is preselected in the new routine form',
      (tester) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: _MemoryRoutineRepository([]),
        logRepository: _MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: _NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 6),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(
          home: RoutineAddScreen(
            initialWeekday: DateTime.thursday,
            returnToRoutines: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('routine-weekday-목')), findsOneWidget);
    expect(find.byKey(const Key('routine-weekday-월')), findsOneWidget);
    expect(find.text('달력에서 선택한 요일을 미리 골랐어요.'), findsOneWidget);
    controller.dispose();
  });
}

class _MemoryRoutineRepository implements RoutineRepository {
  _MemoryRoutineRepository(this.items);

  final List<Routine> items;

  @override
  Future<void> addRoutine(Routine routine) async => items.add(routine);

  @override
  Future<void> deleteRoutine(String routineId) async {
    items.removeWhere((routine) => routine.id == routineId);
  }

  @override
  Future<List<Routine>> loadRoutines() async => List.of(items);

  @override
  Future<void> saveRoutines(List<Routine> routines) async {
    items
      ..clear()
      ..addAll(routines);
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    final index = items.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      items.add(routine);
    } else {
      items[index] = routine;
    }
  }
}

class _MemoryLogRepository implements RoutineLogRepository {
  final List<RoutineLog> _logs = [];

  @override
  Future<void> deleteLogForRoutineOnDate(
      String routineId, String dateYmd) async {
    _logs.removeWhere(
      (log) => log.routineId == routineId && log.dateYmd == dateYmd,
    );
  }

  @override
  Future<void> deleteLogsForRoutine(String routineId) async {
    _logs.removeWhere((log) => log.routineId == routineId);
  }

  @override
  Future<List<RoutineLog>> loadAllLogs() async => List.of(_logs);

  @override
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal) async =>
      const [];

  @override
  Future<void> upsertLog(RoutineLog log) async {
    final index = _logs.indexWhere((item) => item.id == log.id);
    if (index == -1) {
      _logs.add(log);
    } else {
      _logs[index] = log;
    }
  }
}

class _NoopNotificationGateway implements LocalNotificationGateway {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => const [];

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    required NotificationDetails details,
    required String payload,
  }) async {}
}
