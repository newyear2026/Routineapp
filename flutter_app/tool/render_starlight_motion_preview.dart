// flutter test --no-pub tool/render_starlight_motion_preview.dart \
//   --dart-define=AUDIT_OUTPUT_DIR=/private/tmp/starlight-motion-frames
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/widgets/home/starlight_home_motion.dart';

void main() {
  const outputDir = String.fromEnvironment(
    'AUDIT_OUTPUT_DIR',
    defaultValue: '/private/tmp/starlight-motion-frames',
  );

  testWidgets('별빛 고양이 홈 모션을 실제 위젯에서 렌더링', (tester) async {
    tester.view
      ..physicalSize = const Size(160, 160)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    Future<void> show(StarlightHomeMode mode) => tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: Container(
                  width: 120,
                  height: 124,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5EEDA),
                    border:
                        Border.all(color: const Color(0xFF28234F), width: 2),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 88,
                      height: 96,
                      child: StarlightHomeMotion(mode: mode),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

    Future<void> capture(String name, int count) async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      for (var frame = 0; frame < count; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();
        final bytes = await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          image.dispose();
          return data!.buffer.asUint8List();
        });
        final file = File(
          '$outputDir/$name/${frame.toString().padLeft(3, '0')}.png',
        );
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes!);
      }
    }

    await show(StarlightHomeMode.idle);
    await tester.runAsync(() async {
      for (final pose in ['idle', 'activity', 'complete']) {
        await precacheImage(
          ResizeImage(
            AssetImage(CharacterPackCatalog.starlightCat.assetFor(pose)!),
            width: 384,
          ),
          key.currentContext!,
        );
      }
      await precacheImage(
        const ResizeImage(
          AssetImage(
              'assets/characters/cat_starlight/v1/prototype/walk_step.png'),
          width: 384,
        ),
        key.currentContext!,
      );
    });
    await tester.pump();
    await capture('idle', 60);
    await show(StarlightHomeMode.active);
    await tester.pump();
    await capture('active', 40);
    await show(StarlightHomeMode.complete);
    await capture('complete', 11);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
