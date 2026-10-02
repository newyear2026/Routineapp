// flutter test --no-pub tool/render_poodle_time_scene.dart \
//   --dart-define=PREVIEW_FONT=/path/to/korean.ttf \
//   --dart-define=AUDIT_OUTPUT_DIR=/private/tmp/poodle-preview
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../test/support/localization.dart';
import '../test/support/test_doubles.dart';

void main() {
  const outputDir = String.fromEnvironment('AUDIT_OUTPUT_DIR',
      defaultValue: 'output/poodle-time-scene');
  testWidgets('푸들 홈 화면 네 시간대 렌더링', (tester) async {
    await initializeDateFormatting();
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isEmpty) throw StateError('PREVIEW_FONT가 필요합니다.');
    final korean = FontLoader('PreviewKorean')
      ..addFont(
          Future.value(ByteData.sublistView(File(fontPath).readAsBytesSync())));
    await korean.load();
    final pixel = FontLoader('PixelifySans')
      ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf'));
    await pixel.load();
    Directory? materialFonts;
    for (var d = File(Platform.resolvedExecutable).parent;
        d.path != d.parent.path;
        d = d.parent) {
      final candidate = Directory('${d.path}/artifacts/material_fonts');
      if (candidate.existsSync()) {
        materialFonts = candidate;
        break;
      }
    }
    if (materialFonts != null) {
      for (final entry in {
        'MaterialIcons': 'MaterialIcons-Regular.otf',
        'Ahem': 'Roboto-Regular.ttf',
      }.entries) {
        final loader = FontLoader(entry.key)
          ..addFont(Future.value(ByteData.sublistView(
              File('${materialFonts.path}/${entry.value}').readAsBytesSync())));
        await loader.load();
      }
    }
    // 이 도구는 flutter test에서만 실행하는 렌더링 하네스다.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('home_widget');
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => true);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    Rect? referenceCard;
    for (final entry in <String, int>{
      'morning': 7,
      'day': 14,
      'sunset': 18,
      'night': 22,
    }.entries) {
      final app = RoutineAppController(
        dataService: RoutineDataService(
          routineRepository: MemoryRoutineRepository([
            dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
            dailyRoutine(id: 'study', title: '공부', startHour: 15, endHour: 16),
            dailyRoutine(
                id: 'dinner', title: '저녁 식사', startHour: 18, endHour: 19),
            dailyRoutine(
                id: 'sleep', title: '취침 준비', startHour: 23, endHour: 24),
          ]),
          logRepository: MemoryLogRepository(),
        ),
        notificationService: RoutineNotificationService(
          exactAlarmsAllowed: () async => false,
          gateway: NoopNotificationGateway(),
          preferencesLoader: () async =>
              NotificationPreferences.firstLaunchDefaults,
        ),
        nowProvider: () => DateTime(2026, 10, 1, entry.value, 19),
        clockAutoRefreshEnabled: false,
      );
      await app.load();
      final key = GlobalKey();
      await tester.pumpWidget(ChangeNotifierProvider.value(
        value: app,
        child: localizedApp(
          home: Theme(
            data: buildRoutineTheme(
              preset: AppThemePreset.poodleGarden,
              fontFamily: 'PreviewKorean',
            ),
            child: CharacterPackScope(
              current: CharacterPackCatalog.poodleGarden,
              ownership: const BundledOnlyOwnership(),
              child: Builder(
                  builder: (context) => MediaQuery(
                        data: MediaQuery.of(context)
                            .copyWith(disableAnimations: true),
                        child: RepaintBoundary(
                            key: key, child: const HomeScreen()),
                      )),
            ),
          ),
        ),
      ));
      await tester.runAsync(() async {
        for (final path in [
          'assets/pack_backgrounds/poodle-header-${entry.key}.png',
          'assets/pack_backgrounds/poodle-card-${entry.key}.png',
          'assets/characters/poodle_garden/v1/approved/idle.png',
        ]) {
          await precacheImage(AssetImage(path), key.currentContext!);
        }
      });
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull);
      final cardRect = tester.getRect(find.byKey(const Key('home-focus-card')));
      if (referenceCard case final previous?) {
        expect(cardRect.top, previous.top, reason: '${entry.key} 카드 상단');
        expect(cardRect.height, previous.height, reason: '${entry.key} 카드 높이');
      } else {
        referenceCard = cardRect;
      }
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final bytes = await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        image.dispose();
        return data!.buffer.asUint8List();
      });
      final out = File('$outputDir/${entry.key}.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!);
      await tester.pumpWidget(const SizedBox());
      app.dispose();
    }
  });
}
