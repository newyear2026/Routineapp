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
import 'package:routine_timer/widgets/home/squirrel_forest_backdrop.dart';
import 'package:routine_timer/widgets/home/squirrel_time_of_day.dart';
import 'package:routine_timer/widgets/settings/current_pack_card.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/localization.dart';
import 'support/test_doubles.dart';

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

  Future<void> pumpSquirrelScreen(
    WidgetTester tester,
    Widget screen,
    int hour,
  ) async {
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
      nowProvider: () => DateTime(2026, 8, 4, hour),
      clockAutoRefreshEnabled: false,
    );
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: controller,
      child: localizedApp(
        home: CharacterPackScope(
          current: CharacterPackCatalog.explorerSquirrel,
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

  testWidgets('진행과 루틴은 같은 밤 숲을 쓰고 움직임은 약하게 한다', (tester) async {
    for (final screen in [
      const TodayProgressScreen(),
      const RoutinesScreen(),
    ]) {
      await pumpSquirrelScreen(tester, screen, 22);
      final backdrop = tester.widget<SquirrelForestBackdrop>(
        find.byType(SquirrelForestBackdrop),
      );
      expect(backdrop.timeOfDay, SquirrelTimeOfDay.night);
      expect(backdrop.motion, SquirrelForestMotion.subtle);
      expect(
          tester
              .widget<SquirrelAtmosphere>(
                find.byType(SquirrelAtmosphere),
              )
              .subtle,
          isTrue);
      expect(
          tester
              .widget<Text>(find.text(screen is RoutinesScreen
                  ? testL10n.routinesTitle
                  : testL10n.progressTitle))
              .style
              ?.color,
          Colors.white);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('설정은 밤 숲을 정지된 배경으로 보여 준다', (tester) async {
    await pumpSquirrelScreen(tester, const SettingsScreen(), 22);
    final backdrop = tester.widget<SquirrelForestBackdrop>(
      find.byType(SquirrelForestBackdrop),
    );
    expect(backdrop.timeOfDay, SquirrelTimeOfDay.night);
    expect(backdrop.motion, SquirrelForestMotion.none);
    expect(find.byType(SquirrelAtmosphere), findsNothing);
    expect(find.byKey(const Key('settings-sky-decoration')), findsNothing);
    expect(find.byType(CurrentPackCard), findsOneWidget);
    expect(
      tester.widgetList<Text>(find.text(testL10n.settingsTitle)).any(
            (text) => text.style?.color == Colors.white,
          ),
      isTrue,
    );
  });
}
