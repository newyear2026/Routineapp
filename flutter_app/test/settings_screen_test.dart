import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/local/onboarding_local_storage.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/onboarding/onboarding_preview_nav.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/settings/current_pack_card.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
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

  Future<RoutineAppController> pumpSettings(
    WidgetTester tester, {
    Future<bool> Function()? openStoreReview,
    bool showStoreReview = true,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 10, 0),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (_, __) => SettingsScreen(
            openStoreReview: openStoreReview ?? () async => true,
            showStoreReview: showStoreReview,
          ),
        ),
        GoRoute(
          path: OnboardingPreviewNav.splashPath,
          builder: (_, __) => const Scaffold(
            body: Center(
              child: Text(
                '읽기 전용 안내',
                key: Key('safe-onboarding-replay'),
              ),
            ),
          ),
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

  testWidgets('탭 목적지이므로 뒤로가기 버튼을 두지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('설정'), findsWidgets);
    expect(find.byTooltip('뒤로'), findsNothing);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('채울 수 없는 스트릭·상태 지표를 하드코딩해 보여주지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // 이전 프로필 카드는 로그와 무관하게 항상 '3일'을 보여줬다.
    expect(find.textContaining('연속 루틴'), findsNothing);
    expect(find.textContaining('이어가는 중'), findsNothing);
    expect(find.text('기분 좋은 하루'), findsNothing);
    expect(find.text('루틴 진행 중'), findsNothing);
  });

  testWidgets('준비 중 항목은 배지로 알리고 이동 화살표를 두지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // '캐릭터'는 캐릭터 팩 화면으로 가는 살아 있는 행이 됐다. 아직 갈 곳이
    // 없는 행으로 앵커를 옮긴다.
    await tester.scrollUntilVisible(find.text('문의하기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('준비 중'), findsWidgets);
    // 갈 곳이 없는 행에 화살표/줄표를 남기지 않는다.
    expect(find.byIcon(Icons.remove_rounded), findsNothing);
  });

  testWidgets('현재 팩 카드가 지금 쓰는 캐릭터를 보여 준다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('캐릭터 팩'), findsOneWidget);
    expect(find.text('별빛 고양이'), findsOneWidget);
    expect(find.text('사용 중'), findsOneWidget);
    expect(find.byKey(const Key('settings-sky-decoration')), findsOneWidget);
    expect(
        find.byKey(const Key('settings-pack-sky-decoration')), findsOneWidget);
    expect(find.byKey(const Key('settings-pack-sky-decoration-right')),
        findsOneWidget);
    expect(find.byKey(const Key('settings-current-pack-portrait')),
        findsOneWidget);
    expect(
      tester
          .widget<AnimatedCat>(find.descendant(
            of: find.byKey(const Key('settings-current-pack-portrait')),
            matching: find.byType(AnimatedCat),
          ))
          .pose,
      CatPose.idle,
    );
  });

  testWidgets('푸들 팩 설정 카드에는 화분과 머리 뒤 꽃을 그리지 않는다', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: const CharacterPackScope(
        current: CharacterPackCatalog.poodleGarden,
        ownership: BundledOnlyOwnership(),
        child: Scaffold(body: CurrentPackCard()),
      ),
    ));

    expect(find.text('푸들 정원 팩'), findsOneWidget);
    expect(find.byKey(const Key('settings-current-pack-portrait')),
        findsOneWidget);
    expect(find.byKey(const Key('settings-pack-sky-decoration')),
        findsNothing);
    expect(find.byKey(const Key('settings-pack-sky-decoration-right')),
        findsNothing);
  });

  testWidgets('외형을 고르는 자리는 팩 카드 하나뿐이다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    // 테마 스와치와 별도 캐릭터 행은 팩으로 흡수됐다. 파는 단위와 고르는
    // 단위가 어긋나지 않도록 진입점을 하나로 유지한다.
    expect(find.text('테마'), findsNothing);
    expect(find.text('캐릭터 팩'), findsOneWidget);
  });

  testWidgets('알림 소리는 푸시 알림이 꺼져 있으면 함께 비활성된다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    expect(find.text('푸시 알림'), findsOneWidget);
    expect(find.text('알림 소리'), findsOneWidget);
    // 비활성 이유를 설명 문구로 함께 보여준다.
    expect(find.text('푸시 알림이 켜져 있을 때만 쓸 수 있어요'), findsOneWidget);
  });

  testWidgets('시작 안내 다시 보기는 확인 없이 진행하지 않는다', (tester) async {
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    await tester.scrollUntilVisible(find.text('시작 안내 다시 보기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pump();
    await tester.tap(find.text('시작 안내 다시 보기'));
    await tester.pump();

    expect(find.text('시작 안내를 다시 진행할까요?'), findsOneWidget);
    await tester.tap(find.text('취소'));
    await tester.pump();
    expect(find.text('시작 안내를 다시 진행할까요?'), findsNothing);
    expect(find.text('설정'), findsWidgets);
  });

  testWidgets('시작 안내 다시 보기는 완료 상태를 초기화하지 않는다', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding.has_seen_intro': true,
      'onboarding.has_completed_initial_routine_setup': true,
      'onboarding.has_handled_notification_setup': true,
    });
    final controller = await pumpSettings(tester);
    addTearDown(controller.dispose);

    await tester.drag(
      find.byType(ListView),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('시작 안내 다시 보기'));
    await tester.pump();
    await tester.tap(find.text('다시 진행'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('safe-onboarding-replay')), findsOneWidget);
    final onboarding = await OnboardingLocalStorage.load();
    expect(onboarding.hasCompletedOnboarding, isTrue);
  });

  testWidgets('리뷰 남기기는 누르면 스토어 페이지를 연다', (tester) async {
    var opened = 0;
    final controller = await pumpSettings(tester, openStoreReview: () async {
      opened++;
      return true;
    });
    addTearDown(controller.dispose);

    await tester.scrollUntilVisible(find.text('리뷰 남기기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('리뷰 남기기'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.text('Google Play를 열 수 없어요.'), findsNothing);
  });

  testWidgets('스토어를 열지 못하면 조용히 끝내지 않고 알린다', (tester) async {
    final controller = await pumpSettings(
      tester,
      openStoreReview: () async => false,
    );
    addTearDown(controller.dispose);

    await tester.scrollUntilVisible(find.text('리뷰 남기기'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('리뷰 남기기'));
    await tester.pump();

    expect(find.text('Google Play를 열 수 없어요.'), findsOneWidget);
  });

  testWidgets('리뷰를 남길 스토어가 없는 플랫폼에서는 행을 숨긴다', (tester) async {
    final controller = await pumpSettings(tester, showStoreReview: false);
    addTearDown(controller.dispose);

    await tester.scrollUntilVisible(find.text('앱 버전'), 200,
        scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    expect(find.text('리뷰 남기기'), findsNothing);
  });
}
