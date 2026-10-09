import 'package:routine_timer/application/home/home_focus_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/review/review_prompt.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_icon_id.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/models/routine_log_status.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/widgets/ds/orbit_bottom_navigation.dart';
import 'package:routine_timer/widgets/ds/routine_mark.dart';
import 'package:routine_timer/widgets/home/starlight_home_motion.dart';

import 'support/test_doubles.dart';
import 'support/localization.dart';
import 'support/routine_test_harness.dart';

void main() {
  setUpRoutineTestEnvironment();

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
    RoutineLogRepository? logRepository,
    ReviewPrompt? reviewPrompt,
  }) async {
    final controller = createTestRoutineController(
      now: now,
      routines: withRoutines ?? routines,
      logRepository: logRepository,
    );
    await controller.load();
    final app = localizedApp(home: const HomeScreen());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: reviewPrompt == null
            ? app
            : Provider.value(value: reviewPrompt, child: app),
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
    expect(find.text('1개'), findsNothing);
  });

  testWidgets('진행 중인 루틴이 없으면 예정을 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 16, 24),
    );
    addTearDown(controller.dispose);

    expect(find.text('예정'), findsWidgets);
    expect(find.text('진행 중'), findsNothing);
    expect(
      tester
          .widget<StarlightHomeMotion>(find.byType(StarlightHomeMotion))
          .focusState,
      HomeFocusState.upcoming,
    );
  });

  testWidgets('진행 중인 루틴이 있으면 진행 중을 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(find.text('진행 중'), findsOneWidget);
    expect(
      tester
          .widget<StarlightHomeMotion>(find.byType(StarlightHomeMotion))
          .focusState,
      HomeFocusState.active,
    );
    expect(find.text('NOW'), findsNothing);
    expect(find.text('NEXT'), findsNothing);
    // 원형 시간표 중앙이 같은 이름을 반복하지 않는다.
    expect(find.text('점심식사'), findsOneWidget);
  });

  testWidgets('원형 시간표의 지금 배지 없이 현재 시각을 중앙에 놓는다', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(find.text('지금'), findsNothing);
    final ring = tester.getRect(find.byKey(const Key('home-timetable-ring')));
    final time =
        tester.getRect(find.byKey(const Key('home-ring-current-time')));
    expect(time.center.dy, closeTo(ring.center.dy, 1));
    expect(find.bySemanticsLabel('지금 12:30'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('선택한 루틴 아이콘을 원형 시간표 안에도 표시한다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
      withRoutines: [
        dailyRoutine(id: 'reading', title: '독서', startHour: 12, endHour: 13)
            .copyWith(iconId: RoutineIconId.paw),
      ],
    );
    addTearDown(controller.dispose);

    final badge = find.byKey(const Key('home-ring-icon-reading'));
    expect(badge, findsOneWidget);
    expect(
      tester
          .widget<RoutineMark>(
            find.descendant(of: badge, matching: find.byType(RoutineMark)),
          )
          .icon,
      RoutineIconId.paw,
    );
    final ring = tester.getRect(find.byKey(const Key('home-timetable-ring')));
    expect(ring.contains(tester.getRect(badge).center), isTrue);
  });

  /// 스크롤 없이 보이는 본문 아래 끝 — 하단 내비게이션 위.
  double visibleBottom(WidgetTester tester) =>
      tester.getRect(find.byType(OrbitBottomNavigation)).top;

  testWidgets('고양이는 첫 카드 안에, 화분은 시간표 옆에 놓인다', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    final card = tester.getRect(find.byKey(const Key('home-focus-card')));
    final cat = tester.getRect(find.byKey(const Key('home-focus-cat')));
    final line = tester.getRect(find.byKey(const Key('home-focus-line')));
    final ring = tester.getRect(find.byKey(const Key('home-timetable-ring')));
    final scene = tester.getRect(find.byKey(const Key('home-timetable-scene')));
    final plant = tester.getRect(find.byKey(const Key('home-timetable-plant')));
    final button =
        tester.getRect(find.byKey(const Key('home-complete-button')));

    expect(find.byKey(const Key('home-timetable-cat')), findsNothing);
    expect(
        card.contains(cat.topLeft) && card.contains(cat.bottomRight), isTrue);
    expect(cat.overlaps(line), isFalse);
    expect(card.bottom, lessThanOrEqualTo(scene.top));
    expect(plant.left, greaterThan(scene.left));
    expect(plant.right, lessThan(ring.center.dx));
    expect(plant.top, greaterThan(ring.center.dy));
    expect(scene.bottom, lessThanOrEqualTo(button.top));
    // 지금 할 일과 누를 버튼이 스크롤 없이 한 화면에 들어온다.
    expect(button.bottom, lessThanOrEqualTo(visibleBottom(tester)));
  });

  testWidgets('작은 화면에서도 카드와 완료 버튼이 스크롤 없이 보인다', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    final card = tester.getRect(find.byKey(const Key('home-focus-card')));
    final cat = tester.getRect(find.byKey(const Key('home-focus-cat')));
    final line = tester.getRect(find.byKey(const Key('home-focus-line')));
    final scene = tester.getRect(find.byKey(const Key('home-timetable-scene')));
    final completeButton =
        tester.getRect(find.byKey(const Key('home-complete-button')));

    expect(
      tester
          .widget<StarlightHomeMotion>(find.descendant(
            of: find.byKey(const Key('home-focus-cat')),
            matching: find.byType(StarlightHomeMotion),
          ))
          .focusState,
      HomeFocusState.active,
    );
    expect(card.contains(cat.center), isTrue);
    expect(cat.overlaps(line), isFalse);
    expect(scene.bottom, lessThanOrEqualTo(completeButton.top));
    expect(scene.width, lessThanOrEqualTo(272));
    expect(completeButton.bottom, lessThanOrEqualTo(visibleBottom(tester)));
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
    expect(
      tester
          .widget<StarlightHomeMotion>(find.byType(StarlightHomeMotion))
          .focusState,
      HomeFocusState.completed,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('home-focus-cat')),
        matching: find.byKey(const Key('starlight-complete-image')),
      ),
      findsOneWidget,
    );

    // 되돌리기 스낵바로 원상복구된다.
    expect(find.text('되돌리기'), findsOneWidget);
    await tester.tap(find.text('되돌리기'));
    await tester.pumpAndSettle();

    expect(controller.todayLogs, isEmpty);
    expect(controller.progressSummary.completed, 0);
  });

  testWidgets('되돌리기 안내는 2초 뒤 저절로 사라진다', (tester) async {
    // 지금 Flutter는 액션이 달린 스낵바를 기본으로 영영 남겨 둔다.
    // 그대로 두면 다른 탭으로 옮겨도 «되돌리기»가 계속 떠 있다.
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    await tapAction(tester, 'home-complete-button');
    expect(find.text('되돌리기'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('완료로 기록했어요'), findsNothing);
    expect(find.text('되돌리기'), findsNothing);
    expect(controller.todayLogs.single.status, RoutineLogStatus.completed);
  });

  testWidgets('완료 기록 쓰기가 실패하면 성공으로 오해하지 않게 알린다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
      logRepository: _FailingLogWriteRepository(),
    );
    addTearDown(controller.dispose);

    await tapAction(tester, 'home-complete-button');

    expect(controller.todayLogs, isEmpty);
    expect(find.text('기록을 저장하지 못했어요. 다시 시도해 주세요.'), findsOneWidget);
    expect(find.text('완료로 기록했어요'), findsNothing);
    expect(find.text('되돌리기'), findsNothing);
  });

  group('리뷰 요청', () {
    late int requests;
    ReviewPrompt readyPrompt() => ReviewPrompt(
          available: true,
          installTimeLoader: () async => DateTime(2026, 8, 1),
          requester: () async => requests++,
          now: () => DateTime(2026, 8, 4, 12, 30),
        );

    setUp(() => requests = 0);

    testWidgets('루틴을 완료하면 스낵바 뒤에 한 박자 쉬고 묻는다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 12, 30),
        reviewPrompt: readyPrompt(),
      );
      addTearDown(controller.dispose);

      await tapAction(tester, 'home-complete-button');
      expect(find.text('완료로 기록했어요'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1300));
      expect(requests, 1);
    });

    testWidgets('스킵이나 나중에는 묻지 않는다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 12, 30),
        reviewPrompt: readyPrompt(),
      );
      addTearDown(controller.dispose);

      await tapAction(tester, 'home-skip-button');
      await tester.pump(const Duration(seconds: 2));
      expect(requests, 0);
    });

    testWidgets('완료 저장이 실패하면 묻지 않는다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 12, 30),
        logRepository: _FailingLogWriteRepository(),
        reviewPrompt: readyPrompt(),
      );
      addTearDown(controller.dispose);

      await tapAction(tester, 'home-complete-button');
      await tester.pump(const Duration(seconds: 2));
      expect(requests, 0);
    });
  });

  testWidgets('건너뛰면 버튼을 숨기고 건너뜀 카드를 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    await tapAction(tester, 'home-skip-button');
    expect(controller.todayLogs.single.status, RoutineLogStatus.skipped);

    expect(find.text('건너뜀'), findsOneWidget);
    expect(find.text('다음 루틴에서 다시 이어가요'), findsOneWidget);
    expect(find.byKey(const Key('home-complete-button')), findsNothing);
    expect(find.byKey(const Key('home-skip-button')), findsNothing);
  });

  testWidgets('미루면 다시 알릴 시각을 보여주고 나중에는 다시 내밀지 않는다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    await tapAction(tester, 'home-snooze-button');
    expect(controller.todayLogs.single.status, RoutineLogStatus.snoozed);

    expect(find.text('미룸'), findsOneWidget);
    expect(find.text('12:45에 다시 알려 드려요'), findsOneWidget);
    expect(find.byKey(const Key('home-snooze-button')), findsNothing);
    expect(find.byKey(const Key('home-complete-button')), findsOneWidget);
    expect(find.byKey(const Key('home-skip-button')), findsOneWidget);
  });

  testWidgets('예정이면 버튼 없이 시작까지 남은 시간을 이름 아래 한 줄로 보여준다', (tester) async {
    // 테스트 글꼴은 글자마다 폭이 글자 크기와 같아 실제보다 넓다.
    // 360dp 실제 글꼴 확인은 기기에서 한다 (DEVICE_VALIDATION.md).
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 13, 35),
      withRoutines: [
        dailyRoutine(id: 'rest', title: '휴식', startHour: 18, endHour: 19),
      ],
    );
    addTearDown(controller.dispose);

    expect(controller.canActOnCurrentSlot, isFalse);
    expect(find.text('예정'), findsOneWidget);
    // 누를 수 없는 버튼은 흐리게 남기지 않고 숨긴다.
    expect(find.byKey(const Key('home-complete-button')), findsNothing);
    expect(find.byKey(const Key('home-snooze-button')), findsNothing);

    final line = find.byKey(const Key('home-focus-line'));
    expect(tester.widget<Text>(line).data, '시작까지 4시간 25분 남음');
    final lineHeight = tester.getSize(line).height;
    final oneLine = tester.getSize(find.text('휴식')).height;
    expect(lineHeight, lessThan(oneLine));
  });

  testWidgets('완료하면 버튼을 숨기고 완료 배지와 몇 번째인지 보여준다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 12, 30),
    );
    addTearDown(controller.dispose);

    expect(find.text('점심식사 완료'), findsOneWidget);

    await tapAction(tester, 'home-complete-button');

    expect(controller.canActOnCurrentSlot, isFalse);
    expect(find.byKey(const Key('home-complete-button')), findsNothing);
    expect(find.text('완료'), findsOneWidget);
    expect(find.text('잘했어요! 오늘 1번째 완료'), findsOneWidget);
  });

  testWidgets('하루가 끝나면 결과를 숫자로 말하고 내일 첫 루틴을 보여준다', (tester) async {
    final logs = MemoryLogRepository()
      ..logs.addAll(const [
        RoutineLog(
          id: 'wake-2026-08-04',
          routineId: 'wake',
          dateYmd: '2026-08-04',
          status: RoutineLogStatus.completed,
        ),
        RoutineLog(
          id: 'lunch-2026-08-04',
          routineId: 'lunch',
          dateYmd: '2026-08-04',
          status: RoutineLogStatus.skipped,
        ),
      ]);
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 20, 0),
      withRoutines: routines.take(3).toList(),
      logRepository: logs,
    );
    addTearDown(controller.dispose);

    expect(find.text('오늘 끝'), findsOneWidget);
    expect(find.text('오늘 일정이 끝났어요'), findsOneWidget);
    // 놓친 루틴이 있으면 «모두 마쳤어요»라고 하지 않는다.
    expect(find.text('완료 1 · 건너뜀 1 · 놓침 1'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('home-focus-next')),
        matching: find.text('07:00'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('home-complete-button')), findsNothing);
    expect(find.text('0개'), findsNothing);
  });

  testWidgets('오늘 루틴이 없으면 빈 상태와 다음 행동을 안내한다', (tester) async {
    final controller = await pumpHome(
      tester,
      now: DateTime(2026, 8, 4, 9, 0),
      withRoutines: const [],
    );
    addTearDown(controller.dispose);

    expect(find.text('루틴을 추가하면\n하루의 흐름이 보여요'), findsOneWidget);
    expect(find.text('새 루틴을 만들어보세요'), findsOneWidget);
    expect(find.byKey(const Key('home-complete-button')), findsNothing);

    // 홈에는 FAB이 없다. 없는 버튼을 안내하는 대신 실제 경로를 화면에 둔다.
    expect(find.byKey(const Key('home-add-routine-button')), findsOneWidget);
    expect(find.textContaining('오른쪽 아래'), findsNothing);
    // 같은 안내를 '다음 일정' 자리에서 한 번 더 반복하지 않는다.
    expect(find.textContaining('루틴 탭에서 하나 추가'), findsNothing);
  });

  group('다음 일정', () {
    final many = <Routine>[
      dailyRoutine(id: 'r1', title: '기상', startHour: 7, endHour: 8),
      dailyRoutine(id: 'r2', title: '아침운동', startHour: 9, endHour: 10),
      dailyRoutine(id: 'r3', title: '점심식사', startHour: 12, endHour: 13),
      dailyRoutine(id: 'r4', title: '오후공부', startHour: 15, endHour: 16),
      dailyRoutine(id: 'r5', title: '저녁식사', startHour: 18, endHour: 19),
      dailyRoutine(id: 'r6', title: '취침', startHour: 23, endHour: 24),
    ];

    testWidgets('목록이 잘리면 헤더 개수 없이 더 보기를 보여준다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 6, 0),
        withRoutines: many,
      );
      addTearDown(controller.dispose);

      // 기상은 포커스 스트립이 맡고, 남은 5개가 다음 일정이 된다.
      expect(controller.homeSnapshotFor(testL10n).upcomingRoutines.length, 5);
      expect(find.text('3 / 5'), findsNothing);
      expect(find.text('5개'), findsNothing);
      expect(find.text('남은 2개 보기'), findsOneWidget);
    });

    testWidgets('목록이 잘리지 않으면 헤더 개수와 더 보기를 표시하지 않는다', (tester) async {
      final controller = await pumpHome(
        tester,
        now: DateTime(2026, 8, 4, 16, 24),
      );
      addTearDown(controller.dispose);

      expect(find.text('1개'), findsNothing);
      expect(find.text('취침'), findsOneWidget);
      expect(find.byKey(const Key('home-more-upcoming-link')), findsNothing);
    });
  });
}

class _FailingLogWriteRepository extends MemoryLogRepository {
  @override
  Future<void> deleteLogForRoutineOnDate(
    String routineId,
    String dateYmd,
  ) async =>
      throw Exception('disk full');

  @override
  Future<void> upsertLog(RoutineLog log) async => throw Exception('disk full');
}
