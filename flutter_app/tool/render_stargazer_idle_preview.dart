// flutter test --no-pub tool/render_stargazer_idle_preview.dart
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
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widgets/home/stargazer_home_motion.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';

import '../test/support/localization.dart';
import '../test/support/routine_test_harness.dart';
import '../test/support/test_doubles.dart';

void main() {
  setUpRoutineTestEnvironment();
  testWidgets('render eight wizard-cat frames inside the actual home screen',
      (tester) async {
    await initializeDateFormatting();
    const output = 'design/stargazer-idle-8/rendered';
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
    final app = createTestRoutineController(
      now: DateTime(2026, 10, 6, 16, 51),
      routines: [
        dailyRoutine(id: 'wake', title: '기상', startHour: 7, endHour: 8),
        dailyRoutine(id: 'study', title: '공부', startHour: 9, endHour: 10),
        dailyRoutine(id: 'rest', title: '휴식', startHour: 15, endHour: 16),
        dailyRoutine(id: 'dinner', title: '저녁 식사', startHour: 18, endHour: 19),
      ],
    );
    await app.load();
    addTearDown(app.dispose);
    final boundaryKey = GlobalKey();
    await tester.pumpWidget(ChangeNotifierProvider<RoutineAppController>.value(
      value: app,
      child: localizedApp(
        theme: buildRoutineTheme(
            preset: AppThemePreset.stargazer, fontFamily: 'PreviewKorean'),
        home: CharacterPackScope(
          current: CharacterPackCatalog.stargazerCat,
          ownership: const BundledOnlyOwnership(),
          child: RepaintBoundary(key: boundaryKey, child: const HomeScreen()),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final asset in [
        StargazerHomeMotion.asset,
        'assets/pack_backgrounds/stargazer-scene-card.png',
        'assets/pack_backgrounds/stargazer-scene-header.png',
      ]) {
        await precacheImage(AssetImage(asset), boundaryKey.currentContext!);
      }
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, boundaryKey.currentContext!);
      }
    });
    await tester.pump();
    expect(find.byKey(const Key('stargazer-idle-image')), findsOneWidget);
    final boundary = boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final card =
        tester.getRect(find.byKey(const Key('home-focus-card'))).inflate(3);

    for (var frame = 0; frame < 8; frame++) {
      if (frame > 0) {
        await tester.pump(StargazerHomeMotion.frameDurations[frame - 1]);
      }
      await tester.pump();
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$output/home-${frame + 1}.png');
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
        File('$output/card-${frame + 1}.png')
            .writeAsBytesSync(cardBytes!.buffer.asUint8List());
        cardImage.dispose();
        picture.dispose();
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
