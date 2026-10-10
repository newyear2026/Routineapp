// 광고 카드의 모서리 지오메트리를 눈으로 확인하는 하네스.
//
// 광고 본문은 AdMob SDK 가 그리는 플랫폼 뷰라 위젯 테스트에서 렌더되지 않는다.
// 그래서 «SDK 가 그릴 것»을 같은 값으로 재현해 카드와의 관계만 본다.
// 실제 광고 스크린샷이 아니라 지오메트리 재구성이다.
//
// 실행: flutter test tool/render_ad_card_shape.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/widgets/ds/app_card.dart';

/// home_upcoming_ad_card.dart 의 실제 값.
const _inset = 8.0;
const _minHeight = 90.0;

/// NativeTemplateStyle 이 그리는 면을 대신한다.
///
/// mainBackgroundColor 는 AppColors.orbitSurface, 즉 카드와 같은 흰색이다.
/// [tint] 를 주면 그 면을 물들여 지오메트리만 드러낸다.
Widget _adBody({required double cornerRadius, Color? tint}) => Container(
      height: _minHeight,
      decoration: BoxDecoration(
        color: tint ?? AppColors.orbitSurface,
        borderRadius: BorderRadius.circular(cornerRadius),
      ),
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        Container(width: 52, height: 52, color: const Color(0xFFD9D4E8)),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
              Container(height: 12, width: 150, color: const Color(0xFFCFC9DF)),
              const SizedBox(height: 7),
              Container(height: 10, width: 110, color: const Color(0xFFE0DBEC)),
            ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          color: const Color(0xFFFFCC66),
          child: const Text('Ad',
              style: TextStyle(fontSize: 10, color: Color(0xFF3A2E00))),
        ),
      ]),
    );

/// 실제 화면과 같은 조립 — 카드를 뒤에 깔고 광고를 _inset 만큼 들여놓는다.
Widget _panel(String caption,
        {required double cornerRadius, Color? tint}) =>
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(caption,
          style: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontFamily: 'Roboto')),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(_inset),
        decoration: appSurfaceDecoration(),
        child: _adBody(cornerRadius: cornerRadius, tint: tint),
      ),
    ]);

void main() {
  testWidgets('광고 카드 모서리 지오메트리', (tester) async {
    Directory? fonts;
    for (var d = File(Platform.resolvedExecutable).parent;
        d.path != d.parent.path;
        d = d.parent) {
      final c = Directory('${d.path}/artifacts/material_fonts');
      if (c.existsSync()) {
        fonts = c;
        break;
      }
    }
    if (fonts == null) throw StateError('material_fonts 캐시가 필요하다.');
    for (final family in ['Roboto', 'Ahem']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(
            File('${fonts.path}/Roboto-Regular.ttf').readAsBytesSync())));
      await loader.load();
    }

    const size = Size(460, 490);
    final key = GlobalKey();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto'),
      home: RepaintBoundary(
        key: key,
        child: Container(
          width: size.width,
          height: size.height,
          color: AppColors.pageBackground,
          padding: const EdgeInsets.all(20),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _panel('A. after cleanup - cornerRadius 0', cornerRadius: 0),
                const SizedBox(height: 22),
                _panel('B. before - cornerRadius 18', cornerRadius: 18),
                const SizedBox(height: 22),
                _panel('C. cornerRadius 0, ad surface tinted to expose geometry',
                    cornerRadius: 0, tint: const Color(0xFFFDECEA)),
              ]),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    Directory('output/pixel-preview').createSync(recursive: true);
    File('output/pixel-preview/ad-card-shape.png').writeAsBytesSync(bytes!);
  });
}
