// Play Console 그래픽 이미지(1024×500)를 런처 아이콘과 같은 원본에서 뽑는다.
//
// 아이콘과 같은 이유다 — 손으로 만든 PNG를 두면 아이콘이 바뀔 때
// 스토어 자료만 옛 모습으로 남는다. 구도는 가로 로크업(아이콘 + 이름 + 태그라인).
//
// 실행:
//   flutter test tool/generate_feature_graphic.dart
//
// 위젯 테스트 하네스를 쓰는 이유는 generate_app_icon.dart와 같다.
// 텍스트가 들어가므로 라틴은 Flutter 캐시의 Roboto, 한글은 시스템
// Apple SD Gothic Neo를 직접 로드한다. 테스트 기본 폰트는 글자를 네모로 그린다.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';

const _width = 1024.0;
const _height = 500.0;

/// Play Console이 배치에 따라 가장자리를 잘라낼 수 있어, 로크업을 안쪽에 둔다.
const _iconSize = 380.0;

void main() {
  testWidgets('런처 아이콘에서 그래픽 이미지를 뽑는다', (tester) async {
    await _loadRoboto();
    await _loadKorean();
    final icon = await tester.runAsync(_loadIcon);
    addTearDown(icon!.dispose);
    final background = await tester.runAsync(() => _backgroundOf(icon));

    await _render(
      tester,
      icon: icon,
      background: background!,
      fileName: 'feature_graphic_ko.png',
      name: '하루한바퀴',
      tagline: '하루 루틴 시간표',
      titleFamily: 'BrandKo',
      bodyFamily: 'BrandBodyKo',
      titleSize: 76,
      titleTracking: 0,
    );
    await _render(
      tester,
      icon: icon,
      background: background,
      fileName: 'feature_graphic_en.png',
      name: 'LOOP PET',
      tagline: 'Your day as a timetable',
      titleFamily: 'Brand',
      bodyFamily: 'BrandBody',
      titleSize: 88,
      titleTracking: -2.5,
    );
    await _render(
      tester,
      icon: icon,
      background: background,
      fileName: 'feature_graphic_es.png',
      name: 'Vuelta al Día',
      tagline: 'Tu día como un horario',
      titleFamily: 'Brand',
      bodyFamily: 'BrandBody',
      titleSize: 72,
      titleTracking: -2.0,
    );
  });
}

Future<Color> _backgroundOf(ui.Image icon) async {
  final pixels = (await icon.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  return Color.fromARGB(
    255,
    pixels.getUint8(0),
    pixels.getUint8(1),
    pixels.getUint8(2),
  );
}

Future<ui.Image> _loadIcon() async {
  final codec = await ui.instantiateImageCodec(
    File('assets/icon/app_icon.png').readAsBytesSync(),
    targetWidth: _iconSize.toInt(),
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
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
  for (final entry
      in {'Brand': 'Roboto-Black.ttf', 'BrandBody': 'Roboto-Medium.ttf'}
          .entries) {
    final file = File('${dir.path}/${entry.value}');
    final loader = FontLoader(entry.key)
      ..addFont(Future.value(ByteData.view(file.readAsBytesSync().buffer)));
    await loader.load();
  }
}

/// 한글 타이틀용 ExtraBold, 태그라인용 Medium.
Future<void> _loadKorean() async {
  const extraBold = '/tmp/dayround-AppleSDGothicNeo-ExtraBold.ttf';
  const medium = '/tmp/dayround-AppleSDGothicNeo-Medium.ttf';
  if (!File(extraBold).existsSync() || !File(medium).existsSync()) {
    final result = await Process.run('python3', [
      '-c',
      'from fontTools.ttLib.ttCollection import TTCollection\n'
          'c = TTCollection("/System/Library/Fonts/AppleSDGothicNeo.ttc")\n'
          'c.fonts[14].save("$extraBold")\n'
          'c.fonts[2].save("$medium")\n',
    ]);
    if (result.exitCode != 0) {
      throw StateError('한글 폰트를 추출하지 못했다: ${result.stderr}');
    }
  }
  for (final entry in {
    'BrandKo': extraBold,
    'BrandBodyKo': medium,
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(
        Future.value(ByteData.view(File(entry.value).readAsBytesSync().buffer)),
      );
    await loader.load();
  }
}

Future<void> _render(
  WidgetTester tester, {
  required ui.Image icon,
  required Color background,
  required String fileName,
  required String name,
  required String tagline,
  required String titleFamily,
  required String bodyFamily,
  required double titleSize,
  required double titleTracking,
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
        child: ColoredBox(
          color: background,
          child: SizedBox(
            width: _width,
            height: _height,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RawImage(
                  image: icon,
                  width: _iconSize,
                  height: _iconSize,
                  filterQuality: FilterQuality.none,
                ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: titleFamily,
                        fontSize: titleSize,
                        color: AppColors.textPrimary,
                        height: 1.1,
                        letterSpacing: titleTracking,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      tagline,
                      style: TextStyle(
                        fontFamily: bodyFamily,
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
