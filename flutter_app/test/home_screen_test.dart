import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';
import 'support/localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  final routines = <Routine>[
    dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
    dailyRoutine(id: 'lunch', title: '점심식사', startHour: 12, endHour: 13),
    dailyRoutine(id: 'dinner', title: '저녁식사', startHour: 18, endHour: 19),
    dailyRoutine(id: 'sleep', title: '취침', startHour: 23, endHour: 24),
  ];

  Future<RoutineAppController> pumpHome(
    WidgetTester tester, {
    required DateTime now,
    List<Routine>? withRoutines,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(withRoutines ?? routines),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => now,
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// 액션 바는 원형 시간표 아래에 있어 기본 테스트 뷰포트에서는 접혀 있다.
  Future<void> tapAction(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  testWidgets('다음 일정은 같은 루틴을 두 번 보여주지 않는다', (tester) async {
    // 16:24 — 진행 중인 루틴이 없고 다음은 저녁식사, 그 뒤가 취침이다.
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 16, 24),
    );
    addTearDown(controller.dispose);

    // 저녁식사는 포커스 스트립에서 한 번만 나온다.
    expect(find.text('저녁식사'), findsOneWidget);
    // 취침도 다음 일정 목록에 한 번만 나온다 (예전에는 두 번 렌더됐다).
    expect(find.text('취침'), findsOneWidget);
    expect(find.text('1개'), findsOneWidget);
  });

  testWidgets('진행 중인 루틴이 없으면 NOW가 아니라 NEXT를 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 16, 24),
    );
    addTearDown(controller.dispose);

    expect(find.text('NEXT'), findsOneWidget);
    expect(find.text('NOW'), findsNothing);
  });

  testWidgets('진행 중인 루틴이 있으면 NOW를 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(find.text('NOW'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);
    // 원형 시간표 중앙이 같은 이름을 반복하지 않는다.
    expect(find.text('점심식사'), findsOneWidget);
  });

  testWidgets('현재 루틴을 완료로 기록하고 되돌릴 수 있다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(controller.canActOnCurrentSlot, isTrue);

    await tapAction(tester, 'home-complete-button');

    expect(controller.todayLogs, hasLength(1));
    expect(controller.todayLogs.single.routineId, 'lunch');
    expect(controller.todayLogs.single.status, RoutineLogStatus.completed);
    expect(controller.progressSummary.completed, 1);

    // 되돌리기 스낵바로 원상복구된다.
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();

    expect(controller.todayLogs, isEmpty);
    expect(controller.progressSummary.completed, 0);
  });

  testWidgets('스킵과 나중에도 홈에서 기록된다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    await tapAction(tester, 'home-skip-button');
    expect(controller.todayLogs.single.status, RoutineLogStatus.skipped);

    expect(find.byKey(const Key('home-snooze-button')), findsOneWidget);
  });

  testWidgets('루틴 시간이 아니면 액션은 비활성이고 이유를 함께 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 16, 24),
    );
    addTearDown(controller.dispose);

    expect(controller.canActOnCurrentSlot, isFalse);
    // 버튼을 숨기지 않고 남겨두되 누를 수 없어야 한다.
    expect(find.byKey(const Key('home-complete-button')), findsOneWidget);

    await tapAction(tester, 'home-complete-button');
    expect(controller.todayLogs, isEmpty);

    // 버튼 라벨은 사유가 아니라 할 일을 말한다.
    expect(find.text('저녁식사 완료하기'), findsOneWidget);
    expect(find.text('지금은 루틴 시간이 아니에요'), findsNothing);

    // 왜 누를 수 없는지는 버튼 아래에서 따로 설명한다 (UI_STANDARDS 4).
    expect(find.textContaining('18:00에 시작해요'), findsOneWidget);
  });

  testWidgets('이미 완료한 뒤에도 라벨은 유지되고 사유만 바뀐다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(find.text('점심식사 완료하기'), findsOneWidget);

    await tapAction(tester, 'home-complete-button');

    expect(controller.canActOnCurrentSlot, isFalse);
    expect(find.text('점심식사 완료하기'), findsOneWidget);
    expect(find.textContaining('이미 완료했어요'), findsOneWidget);
  });

  testWidgets('오늘 루틴이 없으면 빈 상태와 다음 행동을 안내한다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 9, 0),
      withRoutines: const [],
    );
    addTearDown(controller.dispose);

    expect(find.text('루틴을 추가하면\n하루의 흐름이 보여요'), findsOneWidget);
    expect(find.text('오늘 루틴이 없어요.'), findsOneWidget);

    // 홈에는 FAB이 없다. 없는 버튼을 안내하는 대신 실제 경로를 화면에 둔다.
    expect(find.byKey(const Key('home-add-routine-button')), findsOneWidget);
    expect(find.textContaining('오른쪽 아래'), findsNothing);
    // 같은 안내를 '다음 일정' 자리에서 한 번 더 반복하지 않는다.
    expect(find.textContaining('루틴 탭에서 하나 추가'), findsNothing);
  });

  group('다음 일정 개수', () {
    final many = <Routine>[
      dailyRoutine(id: 'r1', title: '기상', startHour: 7, endHour: 8),
      dailyRoutine(id: 'r2', title: '아침운동', startHour: 9, endHour: 10),
      dailyRoutine(id: 'r3', title: '점심식사', startHour: 12, endHour: 13),
      dailyRoutine(id: 'r4', title: '오후공부', startHour: 15, endHour: 16),
      dailyRoutine(id: 'r5', title: '저녁식사', startHour: 18, endHour: 19),
      dailyRoutine(id: 'r6', title: '취침', startHour: 23, endHour: 24),
    ];

    testWidgets('목록이 잘리면 헤더도 보이는 수를 함께 말한다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 6, 0),
        withRoutines: many,
      );
      addTearDown(controller.dispose);

      // 기상은 NEXT 스트립이 맡고, 남은 5개가 다음 일정이 된다.
      expect(controller.homeSnapshot.upcomingRoutines.length, 5);
      // 전체 개수만 적으면 3개만 그려진 화면과 어긋난다.
      expect(find.text('3 / 5'), findsOneWidget);
      expect(find.text('5개'), findsNothing);
      expect(find.text('남은 2개 보기'), findsOneWidget);
    });

    testWidgets('잘리지 않으면 개수만 적고 더 보기를 붙이지 않는다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 16, 24),
      );
      addTearDown(controller.dispose);

      expect(find.text('1개'), findsOneWidget);
      expect(find.byKey(const Key('home-more-upcoming-link')), findsNothing);
    });
  });
}
