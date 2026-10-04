import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:routine_timer/widgets/ds/app_status_badge.dart';
import 'package:routine_timer/widgets/ds/pixel_decoration.dart';
import 'support/localization.dart';
import 'support/routine_test_harness.dart';

/// 목록·캘린더 전환 칸이 트랙 높이를 다 쓰는지 확인한다.
///
/// Row에 stretch가 없으면 각 칸이 내용 높이(약 19)로만 잡혀, 선택된 흰 pill이
/// 가운데 떠 보이고 트랙 위아래 절반이 눌리지 않았다.
void _expectSwitchFillsTrack(WidgetTester tester) {
  for (final label in ['목록', '달력']) {
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
    tester.getSize(find.byKey(const Key('routine-view-달력'))).width,
  );
}

void main() {
  setUpRoutineTestEnvironment();

  testWidgets('calendar view selects a day and projects its repeated routines',
      (tester) async {
    final controller = createTestRoutineController(
      now: DateTime(2026, 8, 6, 8, 30),
      routines: [
        const Routine(
          id: 'thursday_walk',
          title: '아침 산책',
          startMinutesFromMidnight: 8 * 60,
          endMinutesFromMidnight: 9 * 60,
          repeatWeekdays: {DateTime.thursday},
          colorValue: 0xFF6C4CF1,
          iconEmoji: '🚶',
        ),
      ],
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(home: const RoutinesScreen()),
      ),
    );

    expect(find.text('아침 산책'), findsOneWidget);
    _expectSwitchFillsTrack(tester);

    // 트랙 맨 윗줄을 눌러도 전환돼야 한다 (예전에는 가운데만 눌렸다).
    final calendarTab = find.byKey(const Key('routine-view-달력'));
    final box = tester.getRect(calendarTab);
    await tester.tapAt(Offset(box.center.dx, box.top + 3));
    await tester.pumpAndSettle();

    expect(find.text('8월 6일 (목)'), findsWidgets);
    expect(find.text('아침 산책'), findsOneWidget);

    await tester.tap(find.byKey(const Key('calendar-day-2026-8-7')));
    await tester.pumpAndSettle();

    expect(find.text('8월 7일 (금)'), findsOneWidget);
    expect(find.text('예정된 루틴이 없어요'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('calendar weekday is preselected in the new routine form',
      (tester) async {
    final controller = createTestRoutineController(
      now: DateTime(2026, 8, 6),
      routines: [],
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(
          home: const RoutineAddScreen(
            initialWeekday: DateTime.thursday,
            returnToRoutines: true,
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('routine-weekday-${DateTime.thursday}')),
        findsOneWidget);
    expect(find.byKey(const Key('routine-weekday-${DateTime.monday}')),
        findsOneWidget);
    expect(find.text('달력에서 선택한 요일을 미리 골랐어요.'), findsOneWidget);
    controller.dispose();
  });

  testWidgets('추가 버튼은 아이콘만 있어도 이름을 읽어준다', (tester) async {
    // 아이콘뿐인 버튼이라 의미 라벨이 없으면 스크린 리더가 «버튼»이라고만
    // 읽는다. 무엇을 하는 버튼인지 알 수 없다.
    final handle = tester.ensureSemantics();
    final controller = createTestRoutineController(
      now: DateTime(2026, 8, 6, 8, 30),
      routines: const [],
    );
    await controller.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(home: const RoutinesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    // 떠 있는 추가 버튼은 목록 탭에만 있다. «오늘»은 목록 끝에 글자 버튼을 둔다.
    expect(find.byKey(const Key('routine-add-button')), findsNothing);
    await tester.tap(find.byKey(const Key('routine-view-목록')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('routine-add-button')), findsOneWidget);
    expect(find.bySemanticsLabel('루틴 추가'), findsOneWidget);

    controller.dispose();
    handle.dispose();
  });

  testWidgets('푸들 정원 팩의 루틴 화면은 구름 대신 잎과 청록색 동작을 쓴다', (tester) async {
    final controller = createTestRoutineController(
      now: DateTime(2026, 9, 23),
      routines: [
        const Routine(
          id: 'wake',
          title: '기상',
          startMinutesFromMidnight: 7 * 60,
          endMinutesFromMidnight: 7 * 60 + 30,
          repeatWeekdays: {
            DateTime.monday,
            DateTime.tuesday,
            DateTime.wednesday,
            DateTime.thursday,
            DateTime.friday,
            DateTime.saturday,
            DateTime.sunday,
          },
          colorValue: 0xFF53B987,
          iconEmoji: '☀️',
        ),
      ],
    );
    await controller.load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: localizedApp(
        theme: buildRoutineTheme(preset: AppThemePreset.poodleGarden),
        home: const CharacterPackScope(
          current: CharacterPackCatalog.poodleGarden,
          ownership: BundledOnlyOwnership(),
          child: RoutinesScreen(),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));

    // 정원 배경은 계속 움직이므로 애니메이션 종료를 기다리지 않는다.
    expect(find.byKey(const Key('routines-sky-decoration')), findsNothing);
    expect(find.byKey(const Key('routines-garden-leaf-left')), findsOneWidget);
    expect(find.byKey(const Key('routines-garden-leaf-right')), findsOneWidget);
    expect(find.byType(GardenLeaf), findsAtLeastNWidgets(4));
    expect(find.byKey(const Key('routines-garden-daisy-left')), findsOneWidget);
    expect(
        find.byKey(const Key('routines-garden-daisy-right')), findsOneWidget);
    expect(
        find.byKey(const Key('routines-garden-daisy-bottom')), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(RoutinesScreen)))
          .scaffoldBackgroundColor,
      const Color(0xFFEEEAF7),
    );
    // 탭을 열면 «오늘»이 먼저다. 목록의 반복 배지는 목록으로 옮겨 가서 본다.
    await tester.tap(find.byKey(const Key('routine-view-목록')));
    await tester.pump(const Duration(milliseconds: 500));
    final selectedTab = tester.widget<Material>(find
        .ancestor(
          of: find.byKey(const Key('routine-view-목록')),
          matching: find.byType(Material),
        )
        .first);
    expect(selectedTab.color, AppThemePreset.poodleGarden.primaryColor);
    final badge =
        tester.widget<AppStatusBadge>(find.byType(AppStatusBadge).first);
    expect(badge.tone, AppStatusBadgeTone.meta);
    expect(tester.widget<Text>(find.text('매일')).style?.color,
        AppThemePreset.poodleGarden.primaryColor);
    final addButton = tester.widget<Material>(find
        .ancestor(
          of: find.byKey(const Key('routine-add-button')),
          matching: find.byType(Material),
        )
        .first);
    expect(addButton.color, AppThemePreset.poodleGarden.primaryColor);

    await tester.tap(find.byKey(const Key('routine-view-달력')));
    await tester.pump(const Duration(milliseconds: 500));
    final selectedDay = tester.widget<Container>(find
        .descendant(
          of: find.byKey(const Key('calendar-day-2026-9-23')),
          matching: find.byType(Container),
        )
        .first);
    expect((selectedDay.decoration! as BoxDecoration).color,
        AppThemePreset.poodleGarden.primaryColor);
  });
}
