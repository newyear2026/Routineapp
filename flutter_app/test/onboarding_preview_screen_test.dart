import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routine_timer/data/local/notification_preferences_storage.dart';
import 'package:routine_timer/data/local/onboarding_local_storage.dart';
import 'package:routine_timer/domain/onboarding/onboarding_preview_nav.dart';
import 'package:routine_timer/screens/onboarding_preview_screen.dart';
import 'package:routine_timer/screens/onboarding_screen.dart';
import 'package:routine_timer/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const completedOnboarding = {
    'onboarding.has_seen_intro': true,
    'onboarding.has_completed_initial_routine_setup': true,
    'onboarding.has_handled_notification_setup': true,
    'prefs.notifications.enabled': true,
    'prefs.notifications.permission_status': 'granted',
    'prefs.notifications.sound_enabled': true,
  };

  setUp(() {
    SharedPreferences.setMockInitialValues(Map.of(completedOnboarding));
  });

  Future<void> expectCompletedFlagsUnchanged() async {
    final state = await OnboardingLocalStorage.load();
    expect(state.hasCompletedOnboarding, isTrue);
    final prefs = await NotificationPreferencesStorage.load();
    expect(prefs.notificationsEnabled, isTrue);
  }

  List<RouteBase> previewRoutes() => [
        GoRoute(
          path: OnboardingPreviewNav.hubPath,
          builder: (_, __) => const OnboardingPreviewScreen(),
        ),
        GoRoute(
          path: OnboardingPreviewNav.splashPath,
          builder: (_, state) => SplashScreen(
            preview: true,
            previewFlow: OnboardingPreviewNav.isFlow(state),
          ),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (_, state) => OnboardingScreen(
            preview: true,
            previewFlow: OnboardingPreviewNav.isFlow(state),
          ),
        ),
      ];

  testWidgets('온보딩 미리보기 허브에 모든 화면 항목이 있다', (tester) async {
    await tester.pumpWidget(
      localizedApp(home: const OnboardingPreviewScreen()),
    );
    await tester.pump();

    expect(find.text('온보딩 미리보기'), findsOneWidget);
    expect(find.text('스플래시'), findsOneWidget);
    expect(find.text('시작 안내 (3페이지)'), findsOneWidget);
    expect(find.text('첫 루틴 설정'), findsOneWidget);
    expect(find.text('알림 설정'), findsOneWidget);
    expect(find.text('처음부터 전체 보기'), findsOneWidget);
  });

  testWidgets('스플래시 미리보기는 완료 플래그를 지우지 않는다', (tester) async {
    final router = GoRouter(
      initialLocation: OnboardingPreviewNav.splash,
      routes: previewRoutes(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(localizedApp(routerConfig: router));
    await tester.pump();

    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    await expectCompletedFlagsUnchanged();
  });

  testWidgets('전체 보기도 완료 플래그를 지우지 않는다', (tester) async {
    final router = GoRouter(
      initialLocation: OnboardingPreviewNav.splashFlow,
      routes: previewRoutes(),
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(localizedApp(routerConfig: router));
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(
      tester.widget<SplashScreen>(find.byType(SplashScreen)).previewFlow,
      isTrue,
    );

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.byType(OnboardingScreen), findsOneWidget);
    await expectCompletedFlagsUnchanged();
  });
}
