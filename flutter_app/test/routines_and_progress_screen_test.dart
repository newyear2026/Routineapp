import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/ds/segmented_progress.dart';
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

  Future<RoutineAppController> pump(
    WidgetTester tester,
    Widget screen, {
    required List<Routine> routines,
    DateTime? now,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(routines),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => now ?? DateTime(2026, 8, 4, 16, 24),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  group('루틴 목록', () {
    testWidgets('카드에 시간과 반복 요일을 함께 보여준다', (tester) async {
      final controller = await pump(
        tester,
        const RoutinesScreen(),
        routines: [
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
          const Routine(
            id: 'gym',
            title: '운동',
            startMinutesFromMidnight: 19 * 60,
            endMinutesFromMidnight: 20 * 60,
            repeatWeekdays: {1, 2, 3, 4, 5},
            colorValue: 0xFFE5866B,
            iconEmoji: '💪',
            updatedAtMs: 2,
          ),
        ],
      );
      addTearDown(controller.dispose);

      // 목록만 보고도 매일인지 평일인지 알 수 있어야 한다.
      // 시각과 반복 주기는 성격이 다르므로 한 문자열로 잇지 않고 배지로
      // 나눈다. 목록을 훑을 때 주기가 시각에 묻히지 않아야 한다.
      expect(find.text('07:00–08:00'), findsOneWidget);
      expect(find.text('19:00–20:00'), findsOneWidget);
      expect(find.text('매일'), findsOneWidget);
      expect(find.text('평일'), findsOneWidget);
      expect(find.byKey(const Key('routines-menu-cat')), findsOneWidget);
      expect(
        tester
            .widget<AnimatedCat>(find.descendant(
              of: find.byKey(const Key('routines-menu-cat')),
              matching: find.byType(AnimatedCat),
            ))
            .pose,
        CatPose.focus,
      );
    });

    testWidgets('캘린더 날짜 셀이 넘치지 않고 개수는 헤더에서 읽힌다', (tester) async {
      final controller = await pump(
        tester,
        const RoutinesScreen(),
        routines: [
          dailyRoutine(id: 'a', title: 'A', startHour: 7, endHour: 8),
          dailyRoutine(
              id: 'b', title: 'B', startHour: 9, endHour: 10, updatedAtMs: 2),
          dailyRoutine(
              id: 'c', title: 'C', startHour: 11, endHour: 12, updatedAtMs: 3),
          dailyRoutine(
              id: 'd', title: 'D', startHour: 13, endHour: 14, updatedAtMs: 4),
          dailyRoutine(
              id: 'e', title: 'E', startHour: 15, endHour: 16, updatedAtMs: 5),
        ],
      );
      addTearDown(controller.dispose);

      await tester.tap(find.byKey(const Key('routine-view-달력')));
      await tester.pumpAndSettle();

      // 셀은 색 점만 남기고, 정확한 개수는 선택 날짜 헤더에서 읽는다.
      expect(find.text('5개'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('오늘 날짜는 선택과 별개로 표시된다', (tester) async {
      final controller = await pump(
        tester,
        const RoutinesScreen(),
        routines: [
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        ],
      );
      addTearDown(controller.dispose);

      await tester.tap(find.byKey(const Key('routine-view-달력')));
      await tester.pumpAndSettle();

      // 다른 날을 골라도 오늘(8/4)은 여전히 표시되어야 한다.
      await tester.tap(find.byKey(const Key('calendar-day-2026-8-12')));
      await tester.pumpAndSettle();
      expect(find.text('8월 12일 (수)'), findsOneWidget);

      BoxDecoration dateCircle(String key) {
        final container = tester.widget<Container>(
          find
              .descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(Container),
              )
              .first,
        );
        return container.decoration! as BoxDecoration;
      }

      // 오늘은 선택과 무관하게 테두리로 남는다.
      expect(dateCircle('calendar-day-2026-8-4').border, isNotNull);
      // 선택된 날은 채움으로 구분된다.
      expect(dateCircle('calendar-day-2026-8-12').color,
          isNot(Colors.transparent));
      // 그 외 날짜에는 아무 표시도 없다.
      expect(dateCircle('calendar-day-2026-8-5').border, isNull);

      // 스크린 리더에도 오늘과 루틴 개수를 알린다.
      expect(
        find.bySemanticsLabel(RegExp(r'8월 4일, 오늘, 루틴 1개')),
        findsOneWidget,
      );
    });
  });

  group('진행 화면', () {
    testWidgets('실제 완료 처리 후 픽셀 막대가 갱신된다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        now: DateTime(2026, 8, 4, 7, 30),
        routines: [
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
          dailyRoutine(id: 'work', title: '집중', startHour: 9, endHour: 10),
          dailyRoutine(id: 'gym', title: '운동', startHour: 19, endHour: 20),
        ],
      );
      addTearDown(controller.dispose);
      expect(
          tester
              .widget<SegmentedProgress>(find.byType(SegmentedProgress))
              .value,
          0);
      await controller.completeCurrent();
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      expect(find.text('33%'), findsOneWidget);
      expect(
          tester
              .widget<SegmentedProgress>(find.byType(SegmentedProgress))
              .value,
          0.33);
      expect(find.bySemanticsLabel('오늘 진행률 33 퍼센트'), findsOneWidget);
      final fills = tester
          .widgetList<FractionallySizedBox>(find.descendant(
            of: find.byType(SegmentedProgress),
            matching: find.byType(FractionallySizedBox),
          ))
          .map((w) => w.widthFactor!)
          .toList();
      expect(fills, hasLength(3));
      expect(fills[0], closeTo(0.99, 0.0001));
      expect(fills.skip(1), everyElement(0.0));
    });

    testWidgets('완료가 0일 때 진행 중인 것처럼 말하지 않는다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        routines: [
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
          dailyRoutine(
              id: 'gym',
              title: '운동',
              startHour: 19,
              endHour: 20,
              updatedAtMs: 2),
        ],
      );
      addTearDown(controller.dispose);

      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.text('아직 시작 전이에요'), findsOneWidget);
      expect(find.text('차근차근 잘하고 있어요'), findsNothing);
      // 좁은 칸에 들어가므로 한 줄을 넘기면 안 된다.
      expect(tester.takeException(), isNull);
    });

    testWidgets('상태는 색뿐 아니라 문구 배지로도 구분된다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        routines: [
          dailyRoutine(id: 'gym', title: '운동', startHour: 19, endHour: 20),
        ],
      );
      addTearDown(controller.dispose);

      // 섹션 제목으로 상태를 읽는다. 예정 행은 chevron만 둔다.
      expect(find.text('예정'), findsOneWidget);
      expect(find.text('완료'), findsOneWidget);
      expect(find.text('완료한 루틴이 아직 없어요'), findsOneWidget);
    });

    testWidgets('시간이 지난 루틴은 목록에서 사라지지 않는다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        // 07–08 기상은 이미 지났고, 19–20 운동은 아직 예정이다.
        now: DateTime(2026, 8, 4, 12, 0),
        routines: [
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
          dailyRoutine(
              id: 'gym',
              title: '운동',
              startHour: 19,
              endHour: 20,
              updatedAtMs: 2),
        ],
      );
      addTearDown(controller.dispose);

      // 분모에는 남아 있으므로 목록에도 남아야 한다.
      expect(find.text('0 / 2'), findsOneWidget);
      expect(find.text('놓침'), findsNWidgets(2));
      expect(find.text('기상'), findsOneWidget);
    });

    testWidgets('진행률은 분수 하나로만 말한다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        now: DateTime(2026, 8, 4, 12, 0),
        routines: [
          dailyRoutine(id: 'gym', title: '운동', startHour: 19, endHour: 20),
        ],
      );
      addTearDown(controller.dispose);

      expect(find.text('0 / 1'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      // 진행률은 막대가 형태로 보여주고, 값은 스크린 리더에 남긴다.
      expect(find.bySemanticsLabel('오늘 진행률 0 퍼센트'), findsOneWidget);
    });

    testWidgets('오늘 루틴이 없으면 빈 막대를 남기지 않는다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        now: DateTime(2026, 8, 4, 12, 0),
        routines: const [],
      );
      addTearDown(controller.dispose);

      expect(find.text('오늘은 루틴이 없어요'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('진행률')), findsNothing);
    });

    testWidgets('건너뛴 루틴이 없으면 그 그룹을 그리지 않는다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        now: DateTime(2026, 8, 4, 12, 0),
        routines: [
          dailyRoutine(id: 'gym', title: '운동', startHour: 19, endHour: 20),
        ],
      );
      addTearDown(controller.dispose);

      expect(find.text('건너뜀'), findsNothing);
      // 개수 단위는 홈·루틴 화면과 같게 쓴다.
      expect(find.text('1개'), findsOneWidget);
    });

    testWidgets('헤더에 응원하는 고양이를 둔다', (tester) async {
      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        routines: [
          dailyRoutine(id: 'gym', title: '운동', startHour: 19, endHour: 20),
        ],
      );
      addTearDown(controller.dispose);

      expect(find.text('오늘도 수고했어요!'), findsOneWidget);
      expect(find.byKey(const Key('progress-menu-cat')), findsOneWidget);
      expect(
        tester
            .widget<AnimatedCat>(find.descendant(
              of: find.byKey(const Key('progress-menu-cat')),
              matching: find.byType(AnimatedCat),
            ))
            .pose,
        CatPose.complete,
      );
    });

    testWidgets('루틴이 두 자리 수여도 진행 수치가 한 줄로 남는다', (tester) async {
      // 히어로 수치를 flex 자식으로 두면 Row가 여유 공간을 비율로 미리
      // 쪼개서, 390pt 폰에서 '0 / 12'(103px)가 배정분(91px)을 넘겨 두 줄로
      // 접혔다. 자릿수가 늘어도 한 줄이어야 한다.
      tester.view
        ..physicalSize = const Size(390, 844)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final controller = await pump(
        tester,
        const TodayProgressScreen(),
        now: DateTime(2026, 8, 4, 12, 0),
        routines: [
          for (var hour = 0; hour < 12; hour++)
            dailyRoutine(
              id: 'r$hour',
              title: '루틴 $hour',
              startHour: hour,
              endHour: hour + 1,
              updatedAtMs: hour + 1,
            ),
        ],
      );
      addTearDown(controller.dispose);

      final count = find.text('0 / 12');
      expect(count, findsOneWidget);
      // 한 줄이면 글자 크기(40) 언저리, 접히면 두 배가 된다.
      expect(tester.getSize(count).height, lessThan(60));
    });
  });
}
