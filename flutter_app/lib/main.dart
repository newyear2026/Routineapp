import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_route_observer.dart';
import 'app_scaffold_messenger.dart';
import 'application/release/release_announcements.dart';
import 'application/routine_app_controller.dart';
import 'application/services/ad_bootstrap.dart';
import 'application/services/ad_policy_service.dart';
import 'application/services/app_telemetry.dart';
import 'application/services/firebase_telemetry.dart';
import 'application/services/notification_runtime.dart';
import 'application/services/play_update_port.dart';
import 'application/update/app_updates_controller.dart';
import 'application/review/review_prompt.dart';
import 'application/store/pack_purchases.dart';
import 'data/local/entitlement_storage.dart';
import 'data/local/first_launch_storage.dart';
import 'data/local/onboarding_local_storage.dart';
import 'domain/models/routine_notification_target.dart';
import 'domain/update/app_update_port.dart';
import 'domain/settings/app_language.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notification_permission_screen.dart';
import 'screens/initial_routine_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/notification_routine_screen.dart';
import 'screens/today_progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/routine_add_screen.dart';
import 'screens/widget_medium_preview_screen.dart';
import 'screens/onboarding_preview_screen.dart';
import 'screens/character_pack_store_screen.dart';
import 'screens/character_pack_detail_screen.dart';
import 'screens/our_apps_screen.dart';
import 'screens/release_notes_screen.dart';
import 'screens/routines_screen.dart';
import 'theme/app_theme.dart';
import 'widget_home/home_widget_sync_service.dart';
import 'widgets/store/character_pack_scope.dart';
import 'widgets/store/purchase_text.dart';
import 'domain/onboarding/onboarding_preview_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseTelemetry();
  // 날짜·시간 포맷을 로케일별로 쓰려면 심볼을 먼저 올려야 한다.
  // 빠뜨리면 ko/es에서 DateFormat이 예외를 던진다.
  await initializeDateFormatting();
  // 선물 수령 기간과 광고 워밍업이 같은 첫 실행 시각을 사용한다. 광고 SDK가
  // 시작되기 전 기록해 광고 노출 여부와 무관하게 남긴다.
  try {
    await FirstLaunchStorage.ensure(DateTime.now());
  } catch (e) {
    debugPrint('first launch timestamp failed: $e');
  }
  if (!kIsWeb) {
    try {
      // Capture the delivered occurrence before load() replaces weekly alarms.
      await NotificationRuntime.instance.readLaunchNotification();
    } catch (e) {
      debugPrint('notification startup failed: $e');
    }
    await HomeWidgetSyncService.instance.init();
    // 기다리지 않는다. 광고는 없어도 앱이 돌아가야 하는 기능이라, 여기서
    // 붙잡으면 SDK가 느린 날 첫 화면이 그만큼 늦게 뜬다.
    unawaited(AdBootstrap.instance.ensureInitialized());
  }

  // 상태바 투명하게
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const RoutineTimerApp());
}

/// 업데이트를 물어볼 상대.
///
/// Play뿐이다. In-App Update API는 다른 어디에도 없고, iOS는 스토어에 묻는
/// 대신 릴리스 노트만 받는다 — 그 결정과 이유는 docs/APP_UPDATE.md 에 있다.
AppUpdatePort _updatePort() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? const PlayUpdatePort()
        : const UnavailableUpdatePort();

/// 팩을 살 상대.
///
/// Play뿐이다. LOOPET은 Android에만 출시하고, 다른 플랫폼에서 플러그인을
/// 부르면 채널이 없어 예외가 난다. 그곳에서는 팩 화면이 «이 기기에서는 살 수
/// 없어요»라고 말한다.
PackPurchases _createPurchases() {
  final android = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final purchases = PackPurchases(
    backend:
        android ? PluginPurchaseBackend() : const UnavailablePurchaseBackend(),
    store: const LocalEntitlementStore(),
    restoreOnStart: android,
  );
  AdPolicyService.instance.isAdFree = () => purchases.adFree;
  unawaited(purchases.start());
  return purchases;
}

class RoutineTimerApp extends StatelessWidget {
  const RoutineTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 컨트롤러보다 먼저 둔다. 컨트롤러가 산 팩을 소유 판정에 넣는다.
        ChangeNotifierProvider(create: (_) => _createPurchases()),
        ChangeNotifierProvider(
          create: (context) => RoutineAppController(
            purchases: context.read<PackPurchases>(),
          )..load(),
        ),
        // 확인은 화면이 시작한다 — 홈이 뜰 때 [AppUpdates.refresh]를 부른다.
        // 여기서 걸면 스플래시·온보딩을 지나는 동안 이미 물어보게 되고,
        // 방금 설치한 사람에게 «새 버전이 있어요»는 말이 되지 않는다.
        ChangeNotifierProvider(create: (_) => AppUpdates(port: _updatePort())),
        // 릴리스 노트는 전 플랫폼이다. 앱이 이미 아는 버전 이름 둘을 견주고
        // 스토어에는 아무것도 묻지 않으므로 iOS에서도 그대로 동작한다.
        ChangeNotifierProvider(create: (_) => ReleaseAnnouncements()),
        // 리뷰 요청은 홈의 완료 버튼이 부른다 — 규칙은 [ReviewPrompt]에.
        Provider(create: (_) => ReviewPrompt()),
      ],
      child: const _ExactAlarmPermissionWatcher(
        child: _NotificationNavigation(
            child: _PurchaseFailureReporter(child: _AppRoot())),
      ),
    );
  }
}

/// Consumes cold-start and foreground taps after data/onboarding are ready.
class _NotificationNavigation extends StatefulWidget {
  const _NotificationNavigation({required this.child});
  final Widget child;
  @override
  State<_NotificationNavigation> createState() =>
      _NotificationNavigationState();
}

class _NotificationNavigationState extends State<_NotificationNavigation>
    with WidgetsBindingObserver {
  RoutineAppController? _app;
  bool _opening = false;
  final _runtime = NotificationRuntime.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runtime.openRequest.addListener(_scheduleOpen);
    _runtime.recordsChanged.addListener(_refreshLogs);
    _router.routeInformationProvider.addListener(_scheduleOpen);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<RoutineAppController>();
    if (!identical(app, _app)) {
      _app?.removeListener(_scheduleOpen);
      _app = app..addListener(_scheduleOpen);
    }
    _scheduleOpen();
  }

  void _refreshLogs() {
    unawaited(_app?.refreshNotificationLogs().catchError((Object e) {
      debugPrint('notification log refresh failed: $e');
    }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshLogs();
  }

  void _scheduleOpen() {
    if (!mounted ||
        _opening ||
        _runtime.openRequest.value == null ||
        _app?.isLoaded != true) {
      return;
    }
    _opening = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final onboarding = await OnboardingLocalStorage.load();
        final request = _runtime.openRequest.value;
        if (!mounted || !onboarding.hasCompletedOnboarding || request == null) {
          return;
        }
        _runtime.openRequest.value = null;
        _router.go(Uri(path: '/notification-routine', queryParameters: {
          'payload': request.target.encode(snooze: false),
          if (request.dateYmd != null) 'date': request.dateYmd!,
        }).toString());
      } catch (e) {
        debugPrint('notification navigation failed: $e');
      } finally {
        _opening = false;
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _runtime.openRequest.removeListener(_scheduleOpen);
    _runtime.recordsChanged.removeListener(_refreshLogs);
    _router.routeInformationProvider.removeListener(_scheduleOpen);
    _app?.removeListener(_scheduleOpen);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 정확 알람 권한은 시스템 설정에서만 바뀐다. 사용자가 그곳을 다녀오면
/// 앱이 화면에 돌아오는 시점에 대조해, 달라졌으면 알림을 다시 건다.
/// 화면 단위로 두면 그 화면을 지나지 않은 경로가 새므로 앱 최상단에 둔다.
class _ExactAlarmPermissionWatcher extends StatefulWidget {
  const _ExactAlarmPermissionWatcher({required this.child});

  final Widget child;

  @override
  State<_ExactAlarmPermissionWatcher> createState() =>
      _ExactAlarmPermissionWatcherState();
}

class _ExactAlarmPermissionWatcherState
    extends State<_ExactAlarmPermissionWatcher> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    context.read<RoutineAppController>().resyncIfExactAlarmPermissionChanged();
    // 앱 밖(Play 스토어)에서 쓴 프로모션 코드 등을 잡는다.
    unawaited(context.read<PackPurchases>().refreshOnResume());
    // 오프라인으로 시작해 준비되지 못한 광고 SDK를 다시 올린다. 준비됐으면
    // 바로 돌아온다.
    if (!kIsWeb) unawaited(AdBootstrap.instance.ensureInitialized());
    // 어느 화면에 있든 앱 복귀 시 확인한다. 간격 제한은 컨트롤러가 맡는다.
    unawaited(context.read<AppUpdates>().refreshOnResume());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// 구매 스트림이 스스로 올린 실패를 어느 화면에 있든 알린다.
///
/// 결제 창은 앱 밖에 떠 있다가 돌아온다. 그 사이 사용자가 팩 화면을 떠났을 수
/// 있어, 실패를 연 화면이 아니라 앱 전체의 스낵바로 말한다.
class _PurchaseFailureReporter extends StatefulWidget {
  const _PurchaseFailureReporter({required this.child});

  final Widget child;

  @override
  State<_PurchaseFailureReporter> createState() =>
      _PurchaseFailureReporterState();
}

class _PurchaseFailureReporterState extends State<_PurchaseFailureReporter> {
  PackPurchases? _purchases;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final purchases = context.read<PackPurchases>();
    if (identical(purchases, _purchases)) return;
    _purchases?.removeListener(_report);
    _purchases = purchases..addListener(_report);
  }

  @override
  void dispose() {
    _purchases?.removeListener(_report);
    super.dispose();
  }

  void _report() {
    final failure = _purchases?.takeFailure();
    final messenger = appScaffoldMessengerKey.currentState;
    if (failure == null || messenger == null) return;
    final l10n = AppLocalizations.of(messenger.context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(purchaseFailureMessage(l10n, failure))));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AppRoot extends StatelessWidget {
  const _AppRoot();

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        return MaterialApp.router(
          scaffoldMessengerKey: appScaffoldMessengerKey,
          // 앱 이름은 로케일마다 다르다. 태스크 스위처 제목도 따라가야 하므로
          // 고정 title 대신 onGenerateTitle을 쓴다.
          onGenerateTitle: (context) => AppLocalizations.of(context).appName,
          debugShowCheckedModeBanner: false,
          // null이면 기기 언어를 따른다. 설정에서 언어를 고른 경우에만 값이 온다.
          locale: app.locale,
          supportedLocales: AppLanguage.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildRoutineTheme(preset: app.currentThemePreset),
          routerConfig: _router,
          // 라우트 전체가 같은 팩을 보도록 네비게이터 바깥에 둔다.
          builder: (context, child) => CharacterPackScope(
            current: app.currentPack,
            ownership: app.packOwnership,
            onSelect: app.selectCharacterPack,
            adViews: app.packAdViews,
            onWatchAd: app.watchAdForPackUnlock,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

// 라우터 설정
final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [appRouteObserver, TelemetryRouteObserver()],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(
        preview: OnboardingPreviewNav.isPreview(state),
        previewFlow: OnboardingPreviewNav.isFlow(state),
      ),
    ),
    GoRoute(
      path: '/notification-permission',
      builder: (context, state) => NotificationPermissionScreen(
        preview: OnboardingPreviewNav.isPreview(state),
        previewFlow: OnboardingPreviewNav.isFlow(state),
      ),
    ),
    GoRoute(
      path: '/routine-setup',
      builder: (context, state) => InitialRoutineSetupScreen(
        preview: OnboardingPreviewNav.isPreview(state),
        previewFlow: OnboardingPreviewNav.isFlow(state),
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/notification-routine',
      builder: (context, state) => NotificationRoutineScreen(
        target: RoutineNotificationTarget.parse(
            state.uri.queryParameters['payload']),
        dateYmd: state.uri.queryParameters['date'],
      ),
    ),
    GoRoute(
      path: '/progress',
      builder: (context, state) => const TodayProgressScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
        path: '/routines', builder: (context, state) => const RoutinesScreen()),
    GoRoute(
      path: '/release-notes',
      builder: (context, state) => const ReleaseNotesScreen(),
    ),
    GoRoute(
      path: '/our-apps',
      builder: (context, state) => const OurAppsScreen(),
    ),
    GoRoute(
      path: '/routine-add',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        final weekday = int.tryParse(
          state.uri.queryParameters['weekday'] ?? '',
        );
        return RoutineAddScreen(
          editRoutineId: id,
          initialWeekday: weekday,
          returnToRoutines: state.uri.queryParameters['returnTo'] == 'routines',
        );
      },
    ),
    GoRoute(
      path: '/widget-medium-preview',
      builder: (context, state) => const WidgetMediumPreviewScreen(),
    ),
    GoRoute(
      path: '/onboarding-preview',
      builder: (context, state) => const OnboardingPreviewScreen(),
    ),
    GoRoute(
      path: '/splash-preview',
      builder: (context, state) => SplashScreen(
        preview: true,
        previewFlow: OnboardingPreviewNav.isFlow(state),
      ),
    ),
    GoRoute(
      path: '/character-packs',
      builder: (context, state) => const CharacterPackStoreScreen(),
    ),
    GoRoute(
      path: '/character-packs/:id',
      builder: (context, state) => CharacterPackDetailScreen(
        packId: state.pathParameters['id']!,
      ),
    ),
  ],
);
