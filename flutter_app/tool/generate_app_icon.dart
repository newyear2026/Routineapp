// 런처 아이콘 원본을 [BrandMark] 벡터에서 직접 렌더링한다.
//
// 손으로 만든 PNG를 두면 브랜드 마크가 바뀔 때마다 아이콘이 따로 논다.
// 화면에 그리는 코드와 같은 소스에서 뽑아야 둘이 어긋나지 않는다.
//
// 실행:
//   flutter test tool/generate_app_icon.dart
//   dart run flutter_launcher_icons
//
// 위젯 테스트 하네스를 쓰는 이유는 toImage가 렌더 트리를 요구하기 때문이다.
// 검증이 목적이 아니므로 test/ 가 아니라 tool/ 에 둔다.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/brand_mark.dart';

/// 아이콘 원본 배경. `app icon.png` 시안에서 뽑은 웜 오프화이트.
const _background = Color(0xFFF7F3EE);

const _canvas = 1024.0;

/// [BrandMark]는 자기 박스의 약 82%를 그린다(궤도 반지름 0.355 + 해·달 0.056).
/// 아래 값은 그 비율을 감안해 정한 것이라, 실제 마크가 캔버스에서 차지하는
/// 지름은 각각 약 68% / 59%가 된다.
const _fullMarkSize = 850.0;

/// 어댑티브 아이콘 전경. 런처가 바깥을 잘라내므로 안전 영역(가운데 66%)
/// 안에 들어오게 더 작게 그린다.
const _adaptiveMarkSize = 740.0;

void main() {
  testWidgets('브랜드 마크에서 런처 아이콘 원본을 뽑는다', (tester) async {
    await _render(
      tester,
      fileName: 'app_icon.png',
      markSize: _fullMarkSize,
      background: _background,
    );
    await _render(
      tester,
      fileName: 'app_icon_foreground.png',
      markSize: _adaptiveMarkSize,
      background: null,
    );
  });
}

Future<void> _render(
  WidgetTester tester, {
  required String fileName,
  required double markSize,
  required Color? background,
}) async {
  tester.view
    ..physicalSize = const Size(_canvas, _canvas)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    RepaintBoundary(
      key: boundaryKey,
      child: Container(
        width: _canvas,
        height: _canvas,
        color: background,
        alignment: Alignment.center,
        child: BrandMark(size: markSize),
      ),
    ),
  );

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // toImage/toByteData는 엔진의 래스터라이즈를 기다린다. 위젯 테스트의 가짜
  // 비동기 존 안에서 그대로 await 하면 영영 완료되지 않으므로 runAsync가 필요하다.
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });

  final file = File('assets/icon/$fileName');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote ${file.path} (${bytes.length} bytes)');
}
