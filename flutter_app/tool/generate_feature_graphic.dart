// Play Console 그래픽 이미지(1024×500) 원본을 [BrandMark]에서 직접 렌더링한다.
//
// 아이콘과 같은 이유다 — 손으로 만든 PNG를 두면 브랜드 마크가 바뀔 때
// 스토어 자료만 옛 모습으로 남는다. 화면에 그리는 코드와 같은 소스에서 뽑는다.
// 구도는 스플래시 화면(splash_screen.dart)의 로크업을 가로로 편 것이다.
//
// 실행:
//   flutter test tool/generate_feature_graphic.dart
//
// 위젯 테스트 하네스를 쓰는 이유는 generate_app_icon.dart와 같다.
// 텍스트가 들어가므로 Flutter가 캐시해 둔 Roboto를 직접 로드한다.
// 테스트 하네스의 기본 폰트는 글자를 네모로 그린다.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/widgets/brand_mark.dart';

const _width = 1024.0;
const _height = 500.0;

/// Play Console이 배치에 따라 가장자리를 잘라낼 수 있어, 로크업을 안쪽에 둔다.
const _markSize = 300.0;

void main() {
  testWidgets('브랜드 마크에서 그래픽 이미지를 뽑는다', (tester) async {
    await _loadRoboto();

    await _render(
      tester,
      fileName: 'feature_graphic_en.png',
      name: 'DayRound',
      tagline: 'Your day as a timetable',
    );
    await _render(
      tester,
      fileName: 'feature_graphic_es.png',
      name: 'Vuelta al Día',
      tagline: 'Tu día como un horario',
    );
  });
}

/// Flutter가 캐시에 받아 둔 Roboto를 테스트 폰트 컬렉션에 등록한다.
/// 안드로이드 기본 폰트와 같아 실제 앱 화면과 인상이 어긋나지 않는다.
Future<void> _loadRoboto() async {
  Directory? dir;
  for (var d = File(Platform.resolvedExecutable).parent;
      d.path != d.parent.path;
      d = d.parent) {
    final candidate = Directory('${d.path}/artifacts/material_fonts');
    if (candidate.existsSync()) {
      dir = candidate;
      break;
    }
  }
  if (dir == null) {
    throw StateError('Roboto를 찾지 못했다 (Flutter 캐시의 material_fonts)');
  }
  for (final entry in {'Brand': 'Roboto-Black.ttf', 'BrandBody': 'Roboto-Medium.ttf'}.entries) {
    final file = File('${dir.path}/${entry.value}');
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    await loader.load();
  }
}

Future<void> _render(
  WidgetTester tester, {
  required String fileName,
  required String name,
  required String tagline,
}) async {
  tester.view
    ..physicalSize = const Size(_width, _height)
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final boundaryKey = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: boundaryKey,
        child: Container(
          width: _width,
          height: _height,
          decoration: const BoxDecoration(gradient: AppColors.pageGradient),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandMark(size: _markSize),
              const SizedBox(width: 40),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontFamily: 'Brand',
                      fontSize: 88,
                      color: AppColors.textPrimary,
                      height: 1.1,
                      letterSpacing: -2.5,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    tagline,
                    style: const TextStyle(
                      fontFamily: 'BrandBody',
                      fontSize: 32,
                      color: AppColors.textMuted,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });

  final file = File('assets/store/$fileName');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
  // ignore: avoid_print
  print('wrote ${file.path} (${bytes.length} bytes)');
}
