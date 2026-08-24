import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'app_route_observer.dart';
import 'app_scaffold_messenger.dart';
import 'application/routine_app_controller.dart';
import 'domain/settings/app_language.dart';
import 'l10n/app_localizations.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notification_permission_screen.dart';
import 'screens/initial_routine_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/today_progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/routine_add_screen.dart';
import 'screens/widget_medium_preview_screen.dart';
import 'screens/routines_screen.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme_preset.dart';
import 'widget_home/home_widget_sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 날짜·시간 포맷을 로케일별로 쓰려면 심볼을 먼저 올려야 한다.
  // 빠뜨리면 ko/es에서 DateFormat이 예외를 던진다.
  await initializeDateFormatting();
  if (!kIsWeb) {
    await HomeWidgetSyncService.instance.init();
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

class RoutineTimerApp extends StatelessWidget {
  const RoutineTimerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RoutineAppController()..load(),
      child: Consumer<RoutineAppController>(
        builder: (context, app, _) {
          return MaterialApp.router(
            scaffoldMessengerKey: appScaffoldMessengerKey,
            title: 'Routine Timer',
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
            theme: ThemeData(
              useMaterial3: true,
              // 투명으로 두면 Scaffold의 bottomNavigationBar 뒤가 칠해지지 않아
              // 루트의 검정이 그대로 드러난다. 페이지 배경색을 기본값으로 둔다.
              scaffoldBackgroundColor: AppColors.pageBackground,
              extensions: <ThemeExtension<dynamic>>[
                AppThemeTokens(preset: app.currentThemePreset),
              ],
            ),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}

// 라우터 설정
final GoRouter _router = GoRouter(
  initialLocation: '/',
  observers: [appRouteObserver],
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/notification-permission',
      builder: (context, state) => const NotificationPermissionScreen(),
    ),
    GoRoute(
      path: '/routine-setup',
      builder: (context, state) => const InitialRoutineSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
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
  ],
);
