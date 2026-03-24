import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/notification_permission_screen.dart';
import 'screens/initial_routine_setup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/today_progress_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/routine_add_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
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
    return MaterialApp.router(
      title: 'Routine Timer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      routerConfig: _router,
    );
  }
}

// 라우터 설정
final GoRouter _router = GoRouter(
  initialLocation: '/',
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
      path: '/routine-add',
      builder: (context, state) => const RoutineAddScreen(),
    ),
  ],
);
