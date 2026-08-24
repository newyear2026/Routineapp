import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/screens/initial_routine_setup_screen.dart';
import 'package:routine_timer/screens/notification_permission_screen.dart';
import 'package:routine_timer/screens/onboarding_screen.dart';
import 'package:routine_timer/screens/routine_add_screen.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_doubles.dart';

/// 언어를 늘리면 문자열 길이가 달라진다 — 스페인어는 한국어보다 2~3배 길다.
/// 화면이 넘치면 Flutter가 레이아웃 중에 오류를 던지므로, 각 화면을 세 언어로
/// 그려보는 것만으로 잘림·넘침을 잡을 수 있다.
///
/// 작은 화면과 큰 시스템 글꼴을 함께 본다. 실제로 잘리는 건 대개 그 조합이다.
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

  const locales = <Locale>[Locale('ko'), Locale('en'), Locale('es')];

  /// 작은 기기(360×640)와 큰 글꼴을 동시에 준다.
  const smallPhone = Size(360, 640);

  List<Routine> sampleRoutines() => [
        dailyRoutine(id: 'wake', title: 'Despertar', startHour: 7, endHour: 8),
        dailyRoutine(id: 'focus', title: 'Concentración', startHour: 14, endHour: 16),
        dailyRoutine(id: 'walk', title: 'Caminata', startHour: 18, endHour: 19),
        dailyRoutine(id: 'read', title: 'Lectura', startHour: 21, endHour: 22),
      ];

  Future<RoutineAppController> makeController() async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(sampleRoutines()),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 8, 4, 14, 30),
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    return controller;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen,
    Locale locale, {
    required double textScale,
    RouterConfig<Object>? routerConfig,
  }) async {
    tester.view.physicalSize = smallPhone * tester.view.devicePixelRatio;
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = smallPhone;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = await makeController();
    addTearDown(controller.dispose);

    Widget wrap(Widget child) => MediaQuery(
          data: MediaQueryData(
            size: smallPhone,
            textScaler: TextScaler.linear(textScale),
          ),
          child: child,
        );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: routerConfig != null
            ? MaterialApp.router(
                routerConfig: routerConfig,
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => wrap(child!),
              )
            : MaterialApp(
                locale: locale,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: screen,
                builder: (context, child) => wrap(child!),
              ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// 화면 하나를 세 언어 × 두 글꼴 배율로 그려본다.
  void screenGroup(String name, Widget Function() build) {
    for (final locale in locales) {
      for (final scale in <double>[1.0, 1.3]) {
        testWidgets('$name — ${locale.languageCode} · 글꼴 ${scale}x',
            (tester) async {
          await pumpScreen(tester, build(), locale, textScale: scale);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  screenGroup('홈', () => const HomeScreen());
  screenGroup('오늘의 진행', () => const TodayProgressScreen());
  screenGroup('루틴 목록', () => const RoutinesScreen());
  screenGroup('설정', () => const SettingsScreen());
  screenGroup('온보딩', () => const OnboardingScreen());
  screenGroup('알림 권한', () => const NotificationPermissionScreen());
  screenGroup('초기 루틴 설정', () => const InitialRoutineSetupScreen());

  // 루틴 추가는 라우터를 통해서만 뒤로가기가 성립한다.
  for (final locale in locales) {
    for (final scale in <double>[1.0, 1.3]) {
      testWidgets('루틴 추가 — ${locale.languageCode} · 글꼴 ${scale}x',
          (tester) async {
        final router = GoRouter(
          initialLocation: '/routine-add',
          routes: [
            GoRoute(
              path: '/routine-add',
              builder: (context, state) => const RoutineAddScreen(),
            ),
          ],
        );
        await pumpScreen(
          tester,
          const SizedBox.shrink(),
          locale,
          textScale: scale,
          routerConfig: router,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
