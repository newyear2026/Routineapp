import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/routines_screen.dart';
import 'package:routine_timer/screens/settings_screen.dart';
import 'package:routine_timer/screens/today_progress_screen.dart';
import 'package:routine_timer/theme/pack_skin.dart';
import 'package:routine_timer/theme/pack_skin_catalog.dart';
import 'package:routine_timer/widgets/home/pack_time_scene.dart';
import 'package:routine_timer/widgets/home/poodle_garden_backdrop.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('푸들 네 시간대는 상단과 카드에 서로 다른 자산을 쓴다', () async {
    final scene =
        PackSkinCatalog.of(CharacterPackCatalog.poodleGarden).timedScene!;
    expect(scene.style, PackSceneStyle.poodle);
    expect(scene.nightBodyColor, isNull, reason: '밤에도 본문은 푸들 팩의 기본 배경색을 유지한다');
    for (final hour in [5, 11, 17, 20]) {
      final header = scene.headerAt(hour);
      final card = scene.cardAt(hour);
      expect(header, isNot(card));
      expect((await rootBundle.load(header)).lengthInBytes, greaterThan(0));
      expect((await rootBundle.load(card)).lengthInBytes, greaterThan(0));
    }
    expect(scene.lightHeaderAt(19), isFalse);
    expect(scene.lightHeaderAt(20), isTrue);
  });

  Future<void> pumpPoodle(WidgetTester tester, Widget screen, int hour) async {
    final controller = RoutineAppController(
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
      nowProvider: () => DateTime(2026, 10, 1, hour),
      clockAutoRefreshEnabled: false,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: localizedApp(
        home: CharacterPackScope(
          current: CharacterPackCatalog.poodleGarden,
          ownership: const BundledOnlyOwnership(),
          child: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: screen,
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('진행·루틴·설정은 푸들 밤 장면을 공유한다', (tester) async {
    for (final screen in [
      const TodayProgressScreen(),
      const RoutinesScreen(),
      const SettingsScreen(),
    ]) {
      await pumpPoodle(tester, screen, 22);
      final backdrop = tester.widget<PoodleGardenBackdrop>(
        find.byType(PoodleGardenBackdrop),
      );
      expect(backdrop.phase, PackScenePhase.night);
      expect(backdrop.headerAsset, contains('poodle-header-night'));
      expect(backdrop.animate, screen is! SettingsScreen);
      if (screen is! SettingsScreen) expect(backdrop.subtle, isTrue);
      expect(find.byType(PoodleGardenAtmosphere),
          screen is SettingsScreen ? findsNothing : findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('팩 스코프의 장면은 카드와 상단을 같은 시간대로 고른다', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: CharacterPackScope(
        current: CharacterPackCatalog.poodleGarden,
        ownership: const BundledOnlyOwnership(),
        child: Builder(builder: (context) {
          final morning = PackTimeScene.of(context, 7)!;
          final sunset = PackTimeScene.of(context, 18)!;
          expect(morning.cardAsset, contains('poodle-card-morning'));
          expect(sunset.cardAsset, contains('poodle-card-sunset'));
          return const SizedBox();
        }),
      ),
    ));
  });

  testWidgets('푸들 파티클은 움직이고 시스템 애니메이션 축소에서 멈춘다', (tester) async {
    Widget scene({required bool disableAnimations}) => MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData()
                  .copyWith(disableAnimations: disableAnimations),
              child: const SizedBox(
                width: 390,
                height: 250,
                child: PoodleGardenAtmosphere(phase: PackScenePhase.night),
              ),
            ),
          ),
        );

    await tester.pumpWidget(scene(disableAnimations: false));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(scene(disableAnimations: true));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
