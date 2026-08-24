import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/initial_routine_setup_screen.dart';
import 'package:routine_timer/screens/notification_permission_screen.dart';
import 'package:routine_timer/screens/onboarding_screen.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/widgets/home/circular_timetable_area.dart';
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

  Future<void> pumpBare(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(localizedApp(home: screen));
    await tester.pumpAndSettle();
  }

  group('온보딩 인트로', () {
    testWidgets('루틴 장식에 이모지를 쓰지 않는다', (tester) async {
      await pumpBare(tester, const OnboardingScreen());

      expect(find.text('🌅'), findsNothing);
      expect(find.text('📚'), findsNothing);
      expect(find.text('🍽️'), findsNothing);
    });

    testWidgets('홈 미리보기는 실제 홈과 같은 원형 시간표 위젯을 쓴다', (tester) async {
      await pumpBare(tester, const OnboardingScreen());
      // 별도 목업을 그리면 실제 화면과 어긋난다.
      expect(find.byType(CircularTimetableArea), findsOneWidget);
    });

    testWidgets('앱이 못 하는 일을 약속하지 않는다', (tester) async {
      await pumpBare(tester, const OnboardingScreen());

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      // 알림에는 액션 버튼이 없다. 알림에서 바로 처리한다고 쓰면 사실과 다르다.
      expect(find.textContaining('알림에서 바로 완료'), findsNothing);
      expect(find.textContaining('홈에서 완료·나중에·스킵'), findsOneWidget);
    });

    testWidgets('액션 용어는 홈과 동일하게 스킵을 쓴다', (tester) async {
      await pumpBare(tester, const OnboardingScreen());

      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('스킵'), findsOneWidget);
      // 홈은 '건너뛰기'가 아니라 '스킵'이다. 온보딩만 다른 말을 쓰면 안 된다.
      expect(find.text('건너뛰기'), findsOneWidget); // 헤더의 건너뛰기 버튼 하나뿐
    });

    testWidgets('활성 페이지 인디케이터는 브랜드색으로 보인다', (tester) async {
      await pumpBare(tester, const OnboardingScreen());

      final dots = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((w) => w.decoration)
          .whereType<BoxDecoration>()
          .toList();

      expect(
        dots.any((d) => d.color == AppColors.orbitPrimary),
        isTrue,
        reason: '옅은 라벤더 인디케이터는 새 배경에서 1.2:1로 보이지 않는다',
      );
    });
  });

  group('루틴 선택', () {
    Future<RoutineAppController> pumpSetup(WidgetTester tester) async {
      final controller = RoutineAppController(
        dataService: RoutineDataService(
          routineRepository: MemoryRoutineRepository(),
          logRepository: MemoryLogRepository(),
        ),
        notificationService: RoutineNotificationService(
          gateway: NoopNotificationGateway(),
          preferencesLoader: () async =>
              NotificationPreferences.firstLaunchDefaults,
        ),
        nowProvider: () => DateTime(2026, 8, 5, 10, 0),
        clockAutoRefreshEnabled: false,
      );
      await controller.load();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: localizedApp(home: const InitialRoutineSetupScreen()),
        ),
      );
      await tester.pumpAndSettle();
      return controller;
    }

    BoxDecoration cardDecoration(WidgetTester tester, String catalogId) {
      final container = tester.widget<AnimatedContainer>(
        find.byKey(Key('routine-choice-$catalogId')),
      );
      return container.decoration! as BoxDecoration;
    }

    testWidgets('선택된 카드와 선택 안 된 카드가 눈으로 구분된다', (tester) async {
      final controller = await pumpSetup(tester);
      addTearDown(controller.dispose);

      // 기본 선택: 기상 O, 공부 X
      final selected = cardDecoration(tester, 'wake');
      final unselected = cardDecoration(tester, 'study');

      expect(selected.color, isNot(unselected.color));
      expect(
        (selected.border! as Border).top.color,
        AppColors.orbitPrimary,
      );
      expect(
        (unselected.border! as Border).top.color,
        AppColors.orbitBorder,
      );
      expect(
        (selected.border! as Border).top.width,
        greaterThan((unselected.border! as Border).top.width),
      );
    });

    testWidgets('추천 루틴은 이모지 대신 색상으로 구분한다', (tester) async {
      final controller = await pumpSetup(tester);
      addTearDown(controller.dispose);

      expect(find.byKey(const Key('routine-color-wake')), findsOneWidget);
      expect(find.text('🌅'), findsNothing);
      expect(find.text('💪'), findsNothing);
    });

    testWidgets('탭하면 선택 상태와 개수가 함께 바뀐다', (tester) async {
      final controller = await pumpSetup(tester);
      addTearDown(controller.dispose);

      expect(find.text('6개 선택됨'), findsOneWidget);

      final study = find.byKey(const Key('routine-choice-study'));
      await tester.ensureVisible(study);
      await tester.pumpAndSettle();
      await tester.tap(study);
      await tester.pumpAndSettle();

      expect(find.text('7개 선택됨'), findsOneWidget);
      expect(
        (cardDecoration(tester, 'study').border! as Border).top.color,
        AppColors.orbitPrimary,
      );
    });

    testWidgets('Primary가 Ghost보다 위에 온다', (tester) async {
      final controller = await pumpSetup(tester);
      addTearDown(controller.dispose);

      final primaryY = tester.getTopLeft(find.text('완료하기')).dy;
      final ghostY = tester.getTopLeft(find.text('나중에 설정할게요')).dy;
      expect(primaryY, lessThan(ghostY));
    });
  });

  group('알림 권한', () {
    testWidgets('알림 예시는 이모지 대신 루틴 색상을 쓴다', (tester) async {
      await pumpBare(tester, const NotificationPermissionScreen());

      expect(find.text('🌅'), findsNothing);
      expect(find.text('📚'), findsNothing);
    });

    testWidgets('상시 애니메이션 없이 정지 상태로 안착한다', (tester) async {
      await pumpBare(tester, const NotificationPermissionScreen());
      // design_system_v2 7.2 — 장식용 모션 금지.
      // 벨이 계속 회전하면 pumpAndSettle 이후에도 애니메이션이 남는다.
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('히어로는 주황 그라데이션이 아니라 브랜드 톤을 쓴다', (tester) async {
      await pumpBare(tester, const NotificationPermissionScreen());

      final hero = tester.widget<Container>(
        find.byKey(const Key('notification-permission-hero')),
      );
      final decoration = hero.decoration! as BoxDecoration;
      expect(decoration.gradient, isNull);
      expect(decoration.color, AppColors.orbitPrimary.withValues(alpha: 0.1));
    });

    testWidgets('문구가 실제 동작과 일치한다', (tester) async {
      await pumpBare(tester, const NotificationPermissionScreen());
      expect(find.textContaining('앱에서 완료하거나'), findsOneWidget);
    });
  });
}
