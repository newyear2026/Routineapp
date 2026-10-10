// flutter test --no-pub tool/render_sheep_motion_preview.dart
// Captures the actual HomeScreen and its card, with in-memory routine data.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widgets/home/sheep_home_motion.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';

import '../test/support/localization.dart';
import '../test/support/routine_test_harness.dart';
import '../test/support/test_doubles.dart';

void main() {
  setUpRoutineTestEnvironment();
  testWidgets('render real routine start and completion transitions',
      (tester) async {
    await initializeDateFormatting();
    const output = 'design/sheep-motion-8';
    const koreanFont = String.fromEnvironment('PREVIEW_FONT',
        defaultValue: '/System/Library/Fonts/AppleSDGothicNeo.ttc');
    await (FontLoader('PreviewKorean')
          ..addFont(Future.value(
              ByteData.sublistView(File(koreanFont).readAsBytesSync()))))
        .load();
    await (FontLoader('PixelifySans')
          ..addFont(rootBundle.load('assets/fonts/PixelifySans.ttf')))
        .load();
    for (var dir = File(Platform.resolvedExecutable).parent;
        dir.path != dir.parent.path;
        dir = dir.parent) {
      final fonts = Directory('${dir.path}/artifacts/material_fonts');
      if (!fonts.existsSync()) continue;
      for (final entry in {
        'MaterialIcons': 'MaterialIcons-Regular.otf',
        'Ahem': 'Roboto-Regular.ttf'
      }.entries) {
        await (FontLoader(entry.key)
              ..addFont(Future.value(ByteData.sublistView(
                  File('${fonts.path}/${entry.value}').readAsBytesSync()))))
            .load();
      }
      break;
    }
    tester.view
      ..physicalSize = const Size(390, 780)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var now = DateTime(2026, 10, 6, 17, 59);
    final app = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository([
          dailyRoutine(
              id: 'dinner', title: '저녁 식사', startHour: 18, endHour: 19),
        ]),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        gateway: NoopNotificationGateway(),
        exactAlarmsAllowed: () async => false,
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      completionHaptic: () async {},
      nowProvider: () => now,
      clockAutoRefreshEnabled: false,
    );
    await app.load();
    var disposed = false;
    addTearDown(() {
      if (!disposed) app.dispose();
    });
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(ChangeNotifierProvider<RoutineAppController>.value(
      value: app,
      child: localizedApp(
        theme: buildRoutineTheme(
            preset: AppThemePreset.mooncloudSheep, fontFamily: 'PreviewKorean'),
        home: CharacterPackScope(
          current: CharacterPackCatalog.mooncloudSheep,
          ownership: const BundledOnlyOwnership(),
          child: RepaintBoundary(key: boundaryKey, child: const HomeScreen()),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final asset in [
        ...SheepHomeMotion.assets.values,
      ]) {
        await precacheImage(AssetImage(asset), boundaryKey.currentContext!);
      }
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, boundaryKey.currentContext!);
      }
    });
    await tester.pump();
    expect(find.byKey(const Key('sheep-idle-image')), findsOneWidget);
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    Future<void> capture(SheepMotionClip clip) async {
      final folder = '$output/${clip.name}/rendered';
      final card =
          tester.getRect(find.byKey(const Key('home-focus-card'))).inflate(3);
      final durations = SheepHomeMotion.durationsFor(clip);
      for (var frame = 0; frame < 8; frame++) {
        if (frame > 0) {
          await tester.pump(durations[frame - 1]);
        }
        await tester.pump();
        expect(
            find.byKey(ValueKey('sheep-${clip.name}-image')), findsOneWidget);
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('$folder/home-${frame + 1}.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(bytes!.buffer.asUint8List());
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawImageRect(
              image,
              Rect.fromLTRB(
                  card.left * 2, card.top * 2, card.right * 2, card.bottom * 2),
              Rect.fromLTWH(0, 0, card.width * 2, card.height * 2),
              Paint());
          final picture = recorder.endRecording();
          final cardImage = await picture.toImage(
              (card.width * 2).ceil(), (card.height * 2).ceil());
          final cardBytes =
              await cardImage.toByteData(format: ui.ImageByteFormat.png);
          File('$folder/card-${frame + 1}.png')
              .writeAsBytesSync(cardBytes!.buffer.asUint8List());
          cardImage.dispose();
          picture.dispose();
          image.dispose();
        });
      }
      await tester.pump(durations.last);
    }

    await capture(SheepMotionClip.idle);

    // Advance the actual routine clock; then complete through the real controller.
    now = DateTime(2026, 10, 6, 18);
    // This tool is a flutter_test rendering harness, with no user storage.
    // ignore: invalid_use_of_visible_for_testing_member
    await app.refreshClockStateForTest();
    await tester.pump();
    await capture(SheepMotionClip.walk);
    expect(find.byKey(const Key('sheep-walk-image')), findsOneWidget);
    await app.completeCurrent();
    await tester.pump();
    await capture(SheepMotionClip.complete);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    app.dispose();
    disposed = true;
  });
}
