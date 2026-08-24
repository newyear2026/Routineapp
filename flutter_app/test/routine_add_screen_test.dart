import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/widgets/ds/ds.dart';
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

  Future<RoutineAppController> pumpAddScreen(
    WidgetTester tester, {
    List<Routine>? routines,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(
          routines ??
              [dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8)],
        ),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 10, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    // 저장 성공 경로가 context.go('/home')을 타므로 실제 라우터가 필요하다.
    final router = GoRouter(
      initialLocation: '/routine-add',
      routes: [
        GoRoute(
          path: '/routine-add',
          builder: (_, __) => const RoutineAddScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('홈')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: localizedApp(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('저장 행동은 하단 CTA 하나뿐이다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    // 헤더의 '저장' 텍스트 버튼과 하단 CTA가 함께 있으면 Primary가 두 개가 된다.
    expect(find.text('저장'), findsNothing);
    expect(find.text('루틴 저장하기'), findsOneWidget);
  });

  testWidgets('하단 저장 바 뒤에 배경이 칠해져 검은 띠가 보이지 않는다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.bottomNavigationBar, isA<ColoredBox>());
    expect(
      (scaffold.bottomNavigationBar! as ColoredBox).color,
      AppColors.pageBackground,
    );
  });

  testWidgets('이름이 비면 원인을 필드 옆 인라인 메시지로 남긴다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    await tester.tap(find.text('루틴 저장하기'));
    await tester.pumpAndSettle();

    // 원인은 필드 가까이에, 스낵바는 보조 안내만 맡는다 (UI_STANDARDS 3).
    expect(find.byType(AppFieldMessage), findsOneWidget);
    expect(find.text('루틴 이름을 입력해 주세요.'), findsOneWidget);
    expect(find.text('입력한 값을 확인해주세요.'), findsOneWidget);

    // 저장되지 않았으므로 기존 루틴 1개 그대로다.
    expect(controller.routines, hasLength(1));
  });

  testWidgets('기본 반복 요일은 평일이고 토·일은 꺼져 있다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    await tester.ensureVisible(find.byKey(const Key('routine-weekday-월')));
    await tester.pumpAndSettle();

    for (final day in ['월', '화', '수', '목', '금']) {
      expect(_weekdaySelected(tester, day), isTrue, reason: '$day이 꺼져 있다');
    }
    for (final day in ['토', '일']) {
      expect(_weekdaySelected(tester, day), isFalse, reason: '$day이 켜져 있다');
    }
  });

  testWidgets('요일을 모두 끄면 저장 대신 인라인 사유를 남긴다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    await tester.enterText(find.byType(TextField), '아침 산책');
    // 요일 줄은 미리보기 아래라 기본 뷰포트에서는 접혀 있다.
    for (final day in ['월', '화', '수', '목', '금']) {
      final finder = find.byKey(Key('routine-weekday-$day'));
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tester.tap(find.text('루틴 저장하기'));
    await tester.pumpAndSettle();

    expect(find.text('반복 요일을 하루 이상 선택해 주세요.'), findsOneWidget);
    expect(controller.routines, hasLength(1));
  });

  testWidgets('이름과 요일이 유효하면 저장된다', (tester) async {
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    await tester.enterText(find.byType(TextField), '아침 산책');
    await tester.pump();
    await tester.tap(find.text('루틴 저장하기'));
    await tester.pumpAndSettle();

    expect(controller.routines, hasLength(2));
    expect(controller.routines.map((r) => r.title), contains('아침 산책'));
    // 저장 후에는 홈으로 돌아간다.
    expect(find.text('홈'), findsOneWidget);
  });

  testWidgets('겹치지 않으면 경고를 띄우지 않는다', (tester) async {
    // 기본 시간은 09:00–10:00, 기존 루틴은 07:00–08:00 — 겹치지 않는다.
    final controller = await pumpAddScreen(tester);
    addTearDown(controller.dispose);

    expect(find.textContaining('시간이 겹쳐요'), findsNothing);
  });

  testWidgets('겹치는 루틴이 있으면 저장 전에 알려준다', (tester) async {
    // 기본 시간(09:00–10:00)과 겹치는 '공부'를 미리 넣어둔다.
    final controller = await pumpAddScreen(
      tester,
      routines: [
        dailyRoutine(id: 'study', title: '공부', startHour: 9, endHour: 10),
      ],
    );
    addTearDown(controller.dispose);

    expect(find.textContaining('“공부”과 시간이 겹쳐요'), findsOneWidget);
  });
}

/// 요일 원의 선택 상태는 Semantics로 노출된다.
bool _weekdaySelected(WidgetTester tester, String label) {
  final node = tester.getSemantics(find.byKey(Key('routine-weekday-$label')));
  // flagsCollection은 Tristate라 bool 비교가 안 된다. 대체 API가 안정될 때까지 유지.
  // ignore: deprecated_member_use
  return node.hasFlag(SemanticsFlag.isSelected);
}
