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
import 'package:routine_timer/widgets/home/scenic_pack_backdrop.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

const packs = [
  CharacterPackCatalog.stargazerCat,
  CharacterPackCatalog.postmanRabbit,
  CharacterPackCatalog.mooncloudSheep,
  CharacterPackCatalog.redPandaTeashop,
  CharacterPackCatalog.otterSeaside,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('home_widget');
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final pack in packs) {
    testWidgets('${pack.id}: 장면·조명·본문색과 시간대 경계', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: CharacterPackScope(
          current: pack,
          ownership: const BundledOnlyOwnership(),
          child: Builder(builder: (context) {
            for (final (hour, phase) in [
              (4, PackScenePhase.night),
              (5, PackScenePhase.morning),
              (10, PackScenePhase.morning),
              (11, PackScenePhase.day),
              (16, PackScenePhase.day),
              (17, PackScenePhase.sunset),
              (19, PackScenePhase.sunset),
              (20, PackScenePhase.night),
              (23, PackScenePhase.night),
              (0, PackScenePhase.night),
            ]) {
              final scene = PackTimeScene.of(context, hour)!;
              expect(scene.phase, phase);
              expect(scene.cardAsset, isNot(scene.spec.headerAt(hour)));
              expect(scene.bodyColor, isNull, reason: '본문은 시간대와 무관하다');
              expect(scene.cardLighting,
                  phase == PackScenePhase.day ? isNull : isNotNull);
              expect(scene.hasLightHeaderText, phase == PackScenePhase.night);
              expect(scene.usesTextVeil, isTrue);
            }
            return const SizedBox();
          }),
        ),
      ));
      final spec = PackSkinCatalog.of(pack).timedScene!;
      for (final asset in [spec.headerAt(12), spec.cardAt(12)]) {
        expect((await rootBundle.load(asset)).lengthInBytes, greaterThan(0));
      }
    });

    testWidgets('${pack.id}: 진행·루틴은 약한 움직임, 설정은 정적 장면', (tester) async {
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
        nowProvider: () => DateTime(2026, 10, 1, 22),
        clockAutoRefreshEnabled: false,
      );
      await app.load();
      addTearDown(app.dispose);
      for (final screen in [
        const TodayProgressScreen(),
        const RoutinesScreen(),
        const SettingsScreen()
      ]) {
        await tester.pumpWidget(ChangeNotifierProvider.value(
          value: app,
          child: localizedApp(
              home: CharacterPackScope(
            current: pack,
            ownership: const BundledOnlyOwnership(),
            child: Builder(
                builder: (context) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(disableAnimations: true),
                      child: screen,
                    )),
          )),
        ));
        await tester.pumpAndSettle();
        final backdrop =
            tester.widget<ScenicPackBackdrop>(find.byType(ScenicPackBackdrop));
        expect(backdrop.phase, PackScenePhase.night);
        expect(backdrop.spec.style, PackSkinCatalog.of(pack).timedScene!.style);
        expect(backdrop.animate, screen is! SettingsScreen);
        if (screen is! SettingsScreen) expect(backdrop.subtle, isTrue);
        expect(find.byType(ScenicPackAtmosphere),
            screen is SettingsScreen ? findsNothing : findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      }
    });
  }

  testWidgets('다섯 팩의 네 시간대 파티클을 카드와 상단에 그린다', (tester) async {
    for (final pack in packs) {
      final spec = PackSkinCatalog.of(pack).timedScene!;
      for (final phase in PackScenePhase.values) {
        await tester.pumpWidget(MaterialApp(
            home: Column(children: [
          SizedBox(
              width: 390,
              height: 250,
              child: ScenicPackBackdrop(spec: spec, phase: phase)),
          SizedBox(
              width: 342,
              height: 164,
              child: ScenicPackAtmosphere(
                  style: spec.style, phase: phase, card: true)),
        ])));
        await tester.pump(const Duration(milliseconds: 900));
        expect(tester.hasRunningAnimations, isTrue);
        expect(tester.takeException(), isNull,
            reason: '${pack.id} ${phase.name}');
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('움직임은 접근성·숨김 탭·백그라운드에서 멈추고 복귀한다', (tester) async {
    Widget scene({bool reduced = false, bool active = true}) => MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduced),
            child: TickerMode(
              enabled: active,
              child: const SizedBox(
                  width: 390,
                  height: 250,
                  child: ScenicPackAtmosphere(
                      style: PackSceneStyle.teashop,
                      phase: PackScenePhase.night)),
            ),
          ),
        );
    await tester.pumpWidget(scene());
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pump(const Duration(milliseconds: 400));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(scene(reduced: true));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(scene(active: false));
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(scene());
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
