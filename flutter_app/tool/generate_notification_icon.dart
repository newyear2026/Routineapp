// 알림 아이콘 원본을 [BrandMark] 에서 뽑는다.
//
// 상태바 아이콘은 색을 쓸 수 없다. 안드로이드는 알파 채널만 읽어 모양을 잡고
// 자기가 정한 색으로 칠한다. 그래서 마크를 그린 뒤 색을 전부 흰색으로 눌러
// 실루엣만 남긴다. 런처 아이콘(@mipmap/ic_launcher)은 어댑티브 아이콘이라
// 이 자리에 쓸 수 없다 — 알림이 조용히 실패한다.
//
// 실행:
//   flutter test tool/generate_notification_icon.dart

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/brand_mark.dart';

/// mdpi 24dp 기준. 안드로이드 밀도별 배율.
const _densities = <String, double>{
  'mdpi': 24,
  'hdpi': 36,
  'xhdpi': 48,
  'xxhdpi': 72,
  'xxxhdpi': 96,
};

/// 상태바가 아이콘 주변을 잘라내므로 안쪽에 여백을 둔다.
const _renderScale = 4.0;

void main() {
  testWidgets('브랜드 마크에서 알림 아이콘을 뽑는다', (tester) async {
    for (final entry in _densities.entries) {
      await _render(tester, density: entry.key, size: entry.value);
    }
  });
}

Future<void> _render(
  WidgetTester tester, {
  required String density,
  required double size,
}) async {
  // 작은 크기로 바로 그리면 획이 뭉개진다. 크게 그린 뒤 줄인다.
  final canvas = size * _renderScale;
  tester.view
    ..physicalSize = Size(canvas, canvas)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: SizedBox(
        width: canvas,
        height: canvas,
        child: Center(child: BrandMark(size: canvas)),
      ),
    ),
  );

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final raw = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();

    // 색을 흰색으로 눌러 실루엣만 남긴다. 알파는 그대로 둔다.
    final pixels = raw!.buffer.asUint8List();
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] == 0) continue;
      pixels[i] = 0xFF;
      pixels[i + 1] = 0xFF;
      pixels[i + 2] = 0xFF;
    }

    final descriptor = ui.ImageDescriptor.raw(
      await ui.ImmutableBuffer.fromUint8List(pixels),
      width: canvas.toInt(),
      height: canvas.toInt(),
      pixelFormat: ui.PixelFormat.rgba8888,
    );
    final codec = await descriptor.instantiateCodec(
      targetWidth: size.toInt(),
      targetHeight: size.toInt(),
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    frame.image.dispose();
    return data!.buffer.asUint8List();
  });

  final file =
      File('android/app/src/main/res/drawable-$density/ic_notification.png');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote ${file.path} (${size.toInt()}px)');
}
