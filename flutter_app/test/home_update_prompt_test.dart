import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/app_route_observer.dart';
import 'package:routine_timer/application/release/release_announcements.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/app_version_service.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/application/update/app_updates_controller.dart';
import 'package:routine_timer/data/local/app_update_storage.dart';
import 'package:routine_timer/data/seed/release_notes.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/update/app_update_port.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

class _DelayedPort implements AppUpdatePort {
  final reply = Completer<UpdateCheckResult>();
  int checks = 0;

  @override
  bool get canCheck => true;
  @override
  Future<UpdateCheckResult> check() {
    checks++;
    return reply.future;
  }

  @override
  Future<bool> openStore() async => true;
}

void main() {
  const homeWidgetChannel = MethodChannel('home_widget');
  const pending = UpdateCheckResult.success(PendingUpdate(versionCode: 7));

  setUp(() {
    SharedPreferences.setMockInitialValues(
        {'launch_gift.cat_stargazer.seen': true});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (_) async => true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  Future<({AppUpdates updates, GoRouter router})> pumpHome(
    WidgetTester tester,
    _DelayedPort port, {
    bool announce = false,
    Completer<AppVersion?>? version,
  }) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final app = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      nowProvider: () => DateTime(2026, 9, 22, 10),
      clockAutoRefreshEnabled: false,
    );
    await app.load();
    final updates = AppUpdates(
      port: port,
      recordLoader: () async => AppUpdateStorage.empty,
      recordSaver: (_) async {},
      versionLoader: () async =>
          const AppVersion(version: '1.0.1', buildNumber: '2'),
    );
    final announcements = ReleaseAnnouncements(
      versionLoader: () async => version == null
          ? const AppVersion(version: '1.0.1', buildNumber: '2')
          : await version.future,
      recordLoader: () async => (
        announcedVersion: announce ? '1.0.0' : '1.0.1',
        readVersion: '1.0.0',
      ),
      recordSaver: (_) async {},
      notes: [
        ReleaseNote(
          version: '1.0.1',
          releasedOn: DateTime(2026, 9, 22),
          lines: [(l10n) => l10n.releaseNote101Snooze],
        ),
      ],
    );
    final router = GoRouter(observers: [
      appRouteObserver
    ], routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
      GoRoute(
          path: '/other',
          builder: (_, __) => const Scaffold(body: Text('other'))),
      GoRoute(
          path: '/release-notes',
          builder: (_, __) => const Scaffold(body: Text('notes'))),
    ]);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      updates.dispose();
      announcements.dispose();
      app.dispose();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: app),
        ChangeNotifierProvider.value(value: updates),
        ChangeNotifierProvider.value(value: announcements),
      ],
      child: localizedApp(routerConfig: router),
    ));
    await tester.pumpAndSettle();
    return (updates: updates, router: router);
  }

  testWidgets('변경점 안내를 닫으면 기다리던 업데이트 팝업이 이어진다', (tester) async {
    final port = _DelayedPort();
    final state = await pumpHome(tester, port, announce: true);
    expect(find.text(testL10n.releaseAnnouncementAction), findsOneWidget);
    port.reply.complete(pending);
    await tester.pumpAndSettle();
    expect(state.updates.shouldPrompt, isTrue);
    expect(find.text(testL10n.updateAvailableTitle), findsNothing);
    await tester.tap(find.text(testL10n.releaseAnnouncementAction));
    await tester.pumpAndSettle();
    expect(find.text(testL10n.updateAvailableTitle), findsOneWidget);
    await tester.tap(find.text(testL10n.updateLater));
    await tester.pumpAndSettle();
    expect(find.text(testL10n.updateBannerMessage), findsOneWidget);
  });

  testWidgets('버전 로딩보다 업데이트 조회가 빨라도 변경점부터 보여 준다', (tester) async {
    final port = _DelayedPort()..reply.complete(pending);
    final version = Completer<AppVersion?>();
    await pumpHome(tester, port, announce: true, version: version);
    expect(find.byType(Dialog), findsNothing);
    version.complete(const AppVersion(version: '1.0.1', buildNumber: '2'));
    await tester.pumpAndSettle();
    expect(find.text(testL10n.releaseAnnouncementAction), findsOneWidget);
    expect(find.text(testL10n.updateAvailableTitle), findsNothing);
    await tester.tap(find.text(testL10n.releaseAnnouncementAction));
    await tester.pumpAndSettle();
    expect(find.text(testL10n.updateAvailableTitle), findsOneWidget);
  });

  testWidgets('다른 화면 위에는 띄우지 않고 홈 복귀 시 표시한다', (tester) async {
    final port = _DelayedPort();
    final state = await pumpHome(tester, port);
    unawaited(state.router.push('/other'));
    await tester.pumpAndSettle();
    port.reply.complete(pending);
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
    expect(state.updates.shouldPrompt, isTrue);
    state.router.pop();
    await tester.pumpAndSettle();
    expect(find.text(testL10n.updateAvailableTitle), findsOneWidget);
  });

  testWidgets('백그라운드에서 받은 결과는 복귀할 때 표시한다', (tester) async {
    final port = _DelayedPort();
    final state = await pumpHome(tester, port);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    port.reply.complete(pending);
    await tester.pump();
    expect(state.updates.shouldPrompt, isTrue);
    expect(find.byType(Dialog), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text(testL10n.updateAvailableTitle), findsOneWidget);
    expect(port.checks, 1);
  });
}
