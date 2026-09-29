// flutter test tool/render_stargazer_preview.dart \
//   --dart-define=PREVIEW_FONT=/System/Library/Fonts/AppleSDGothicNeo.ttc
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/theme/app_theme.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/widget_medium/home_medium_widget.dart';
import 'package:routine_timer/widget_medium/home_medium_widget_view_model.dart';
import 'package:routine_timer/widget_medium/medium_ring_segment.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/ds/pixel_decoration.dart';
import 'package:routine_timer/widgets/store/launch_gift_dialog.dart';

import '../test/support/localization.dart';

const _pack = CharacterPackCatalog.stargazerCat;

const _viewModel = HomeMediumWidgetViewModel(
  currentRoutineTitle: '저녁식사',
  currentRoutineTimingHint: '종료까지 58분 남음',
  currentRoutineStatusLabel: '진행 중',
  nextRoutineTitle: '취침',
  nextRoutineTime: '23:00',
  currentTime: TimeOfDay(hour: 18, minute: 2),
  centerTimeLabel: '지금',
  activeSegmentId: 'dinner',
  ringSegments: [
    MediumRingSegment(
      id: 'dinner',
      startMinutesFromMidnight: 18 * 60,
      sweepMinutes: 60,
      color: Color(0xFFF4C430),
    ),
    MediumRingSegment(
      id: 'sleep',
      startMinutesFromMidnight: 23 * 60,
      sweepMinutes: 60,
      color: Color(0xFF3B5BD9),
    ),
  ],
);

void main() {
  testWidgets('Stargazer Cat app-size preview', (tester) async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isEmpty) throw StateError('PREVIEW_FONT is required');
    await (FontLoader('PreviewKorean')
          ..addFont(Future.value(
              ByteData.sublistView(File(fontPath).readAsBytesSync()))))
        .load();

    tester.view
      ..physicalSize = const Size(1040, 700)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(localizedApp(
      theme: buildRoutineTheme(
        preset: AppThemePreset.stargazer,
        fontFamily: 'PreviewKorean',
      ),
      home: Scaffold(
        backgroundColor: AppThemePreset.stargazer.pageBackground,
        body: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: AppThemePreset.stargazer.pageBackground,
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('유성 관측 고양이 · 실제 표시 크기',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (final pose in CatPose.values) _PoseCard(pose: pose),
                    ],
                  ),
                  const SizedBox(height: 35),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 360,
                        height: 164,
                        decoration: BoxDecoration(
                          gradient: AppThemePreset.stargazer.focusCardGradient,
                          border: Border.all(
                              color: const Color(0xFF0B5968), width: 2),
                        ),
                        child: const Stack(children: [
                          Positioned(
                              top: 20,
                              left: 18,
                              child:
                                  Text('진행 중', style: TextStyle(fontSize: 14))),
                          Positioned(
                              top: 48,
                              left: 18,
                              child: Text('저녁식사',
                                  style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold))),
                          Positioned(
                              top: 89,
                              left: 18,
                              child: Text('58분 남음 · 다음 취침 23:00',
                                  style: TextStyle(fontSize: 14))),
                          Positioned(
                            right: 4,
                            bottom: 4,
                            width: 88,
                            height: 96,
                            child: AnimatedCat(
                                pose: CatPose.idle,
                                animate: false,
                                pack: _pack),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 36),
                      const SizedBox(
                        width: 330,
                        child: HomeMediumWidget(
                          viewModel: _viewModel,
                          characterPackId: 'cat_stargazer',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Row(children: [
                    PixelDecoration(asset: 'stargazer-telescope', size: 48),
                    SizedBox(width: 18),
                    PixelDecoration(asset: 'stargazer-meteor', size: 48),
                    SizedBox(width: 18),
                    PixelDecoration(
                        asset: 'stargazer-celestial-globe', size: 48),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      for (final pose in CharacterPack.poseNames) {
        await precacheImage(
            AssetImage(_pack.assetFor(pose)!), key.currentContext!);
      }
      for (final deco in _pack.decoIds) {
        await precacheImage(
            AssetImage('assets/decorations/$deco.png'), key.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    final output = File('design/stargazer-source/app-size-preview.png');
    output.writeAsBytesSync(bytes!);
  });

  testWidgets('Stargazer Cat gift card preview', (tester) async {
    const fontPath = String.fromEnvironment('PREVIEW_FONT');
    if (fontPath.isEmpty) throw StateError('PREVIEW_FONT is required');
    await (FontLoader('PreviewKorean')
          ..addFont(Future.value(
              ByteData.sublistView(File(fontPath).readAsBytesSync()))))
        .load();
    tester.view
      ..physicalSize = const Size(540, 680)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final key = GlobalKey();
    await tester.pumpWidget(localizedApp(
      theme: buildRoutineTheme(fontFamily: 'PreviewKorean'),
      home: Scaffold(
        backgroundColor: AppThemePreset.stargazer.pageBackground,
        body: Center(
          child: RepaintBoundary(
            key: key,
            child: Container(
              width: 360,
              color: const Color(0xFF0B3D4A),
              child: LaunchGiftCard(onClose: () {}, onUse: () {}),
            ),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await precacheImage(
          AssetImage(_pack.assetFor('idle')!), key.currentContext!);
      for (final deco in _pack.decoIds) {
        await precacheImage(
            AssetImage('assets/decorations/$deco.png'), key.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    File('design/stargazer-source/gift-preview.png').writeAsBytesSync(bytes!);
  });
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({required this.pose});

  final CatPose pose;

  @override
  Widget build(BuildContext context) => Container(
        width: 145,
        height: 154,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFEFA),
          border: Border.all(color: const Color(0xFFD9E6E4)),
        ),
        child: Column(children: [
          const SizedBox(height: 9),
          SizedBox(
            width: 88,
            height: 96,
            child: AnimatedCat(pose: pose, animate: false, pack: _pack),
          ),
          const SizedBox(height: 10),
          Text(pose.name, style: const TextStyle(fontSize: 13)),
        ]),
      );
}
