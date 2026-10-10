// 아이콘 픽셀화 시안 — 코드에 반영하기 전에 눈으로 먼저 고르기 위한 렌더 하네스다.
// 실행: flutter test tool/render_pixel_icons.dart
// 결과: output/pixel-preview/icons-*.png
//
// 패턴은 lib/widgets/ds/pixel_nav_icon.dart 와 같은 12×12 그리드를 쓴다.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/app_colors.dart';
import 'package:routine_timer/theme/app_pixel_style.dart';

/// 후보 글리프. 이름 → 12행 12열 패턴.
const _glyphs = <String, List<String>>{
  'chevron': [
    '............',
    '...##.......',
    '....##......',
    '.....##.....',
    '......##....',
    '.......##...',
    '.......##...',
    '......##....',
    '.....##.....',
    '....##......',
    '...##.......',
    '............',
  ],
  // v1: 글리프가 12행 중 7행만 차지해 버튼 안에서 작아 보였다.
  'checkV1': [
    '............',
    '............',
    '.........##.',
    '........##..',
    '.......##...',
    '.##...##....',
    '..##.##.....',
    '...###......',
    '...##.......',
    '............',
    '............',
    '............',
  ],
  // v2: 그리드 폭을 꽉 채우고 세로도 8행으로 늘렸다.
  'check': [
    '............',
    '............',
    '..........##',
    '.........##.',
    '........##..',
    '.......##...',
    '##....##....',
    '.##..##.....',
    '..####......',
    '...##.......',
    '............',
    '............',
  ],
  'add': [
    '............',
    '............',
    '.....##.....',
    '.....##.....',
    '.....##.....',
    '..########..',
    '..########..',
    '.....##.....',
    '.....##.....',
    '.....##.....',
    '............',
    '............',
  ],
  // A안: 하단 네비 '설정' 아이콘과 완전히 같은 패턴을 재사용한다.
  'settingsA': [
    '....####....',
    '....####....',
    '.###....###.',
    '.##......##.',
    '##...##...##',
    '##..####..##',
    '##..####..##',
    '##...##...##',
    '.##......##.',
    '.###....###.',
    '....####....',
    '....####....',
  ],
  // B안: 가운데를 비워 작은 크기에서 톱니가 더 또렷하게 읽히도록 한다.
  'settingsB': [
    '....####....',
    '....####....',
    '.###....###.',
    '.##......##.',
    '##..####..##',
    '##.##..##.##',
    '##.##..##.##',
    '##..####..##',
    '.##......##.',
    '.###....###.',
    '....####....',
    '....####....',
  ],
  // 슬라이더 A안: 가로 트랙 3개 + 손잡이. 픽셀 그리드가 가장 잘 맞는 형태다.
  'sliderA': [
    '........##..',
    '############',
    '........##..',
    '............',
    '...##.......',
    '############',
    '...##.......',
    '............',
    '......##....',
    '############',
    '......##....',
    '............',
  ],
  // 슬라이더 B안: 트랙 2개를 2픽셀로 굵게. 작은 크기에서 더 단단하게 보인다.
  'sliderB': [
    '............',
    '........##..',
    '############',
    '############',
    '........##..',
    '............',
    '...##.......',
    '############',
    '############',
    '...##.......',
    '............',
    '............',
  ],
  // 네비 스트립 비교용 — lib/widgets/ds/pixel_nav_icon.dart 의 0~2번 패턴.
  'navHome': [
    '.....##.....',
    '....####....',
    '...##..##...',
    '..##....##..',
    '.##......##.',
    '##........##',
    '..#......#..',
    '..#......#..',
    '..#..##..#..',
    '..#..##..#..',
    '..########..',
    '............',
  ],
  'navChart': [
    '............',
    '.........##.',
    '.........##.',
    '.....##..##.',
    '.....##..##.',
    '.....##..##.',
    '.##..##..##.',
    '.##..##..##.',
    '.##..##..##.',
    '.##..##..##.',
    '.##########.',
    '............',
  ],
  'navList': [
    '............',
    '.##..######.',
    '.##..######.',
    '............',
    '............',
    '.##..######.',
    '.##..######.',
    '............',
    '............',
    '.##..######.',
    '.##..######.',
    '............',
  ],
};

class _PixelGlyph extends StatelessWidget {
  const _PixelGlyph(this.name, {required this.size, required this.color});
  final String name;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(
      size: Size(size, size), painter: _GlyphPainter(_glyphs[name]!, color));
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter(this.pattern, this.color);
  final List<String> pattern;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final cell = size.width / 12;
    for (var y = 0; y < 12; y++) {
      for (var x = 0; x < 12; x++) {
        if (pattern[y][x] == '#') {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.pattern != pattern || old.color != color;
}

// ── 시트 조립 ────────────────────────────────────────────────────────────────

const _ink = AppColors.textPrimary;
const _muted = AppColors.textMuted;

TextStyle get _label =>
    const TextStyle(fontSize: 13, color: _muted, height: 1.3);
TextStyle get _heading => const TextStyle(
    fontSize: 17, color: _ink, fontWeight: FontWeight.w700, height: 1.3);
TextStyle get _caption =>
    const TextStyle(fontSize: 11, color: _muted, height: 1.3);

BoxDecoration get _surface => BoxDecoration(
      color: AppColors.orbitSurface,
      border: Border.all(color: AppPixelStyle.outline, width: 2),
      boxShadow: const [
        BoxShadow(color: AppPixelStyle.shadow, offset: AppPixelStyle.cardOffset)
      ],
    );

/// 한 아이콘의 Material 원본 / 픽셀 시안 비교 열.
Widget _compareColumn(String title, IconData material, String glyph) {
  return SizedBox(
      width: 196,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
    Text(title, style: _label, textAlign: TextAlign.center),
    const SizedBox(height: 10),
    Container(
      width: 128,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: _surface,
      child: Column(children: [
        Icon(material, size: 56, color: _ink),
        const SizedBox(height: 4),
        Text('Material', style: _caption),
        const SizedBox(height: 14),
        Container(height: 2, width: 96, color: AppColors.orbitBorder),
        const SizedBox(height: 14),
        _PixelGlyph(glyph, size: 56, color: _ink),
        const SizedBox(height: 4),
        Text('Pixel', style: _caption),
      ]),
    ),
    const SizedBox(height: 12),
    // 실제로 쓰이는 크기(24pt)에서의 가독성.
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(material, size: 24, color: _ink),
      const SizedBox(width: 14),
      _PixelGlyph(glyph, size: 24, color: _ink),
    ]),
    const SizedBox(height: 4),
    Text('24pt (actual use)', style: _caption),
  ]));
}

/// 루틴 행 — chevron 적용 전/후.
Widget _routineRow({required bool pixel}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: _surface,
    child: Row(children: [
      Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
              color: AppColors.orbitAccent,
              border: Border.all(color: _ink, width: 2))),
      const SizedBox(width: 14),
      Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
            const Text('Morning',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700, color: _ink)),
            const SizedBox(height: 2),
            Text('07:00-08:00', style: _label),
          ])),
      pixel
          ? const _PixelGlyph('chevron', size: 24, color: _muted)
          : const Icon(Icons.chevron_right_rounded, size: 24, color: _muted),
    ]),
  );
}

/// 주 버튼 — check 적용 전/후.
Widget _primaryButton(
    {required bool pixel, String glyph = 'check', double size = 26}) {
  return Container(
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.orbitPrimary,
      border: Border.all(color: AppPixelStyle.outline, width: 2),
      boxShadow: const [
        BoxShadow(color: AppPixelStyle.shadow, offset: AppPixelStyle.cardOffset)
      ],
    ),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      pixel
          ? _PixelGlyph(glyph, size: size, color: Colors.white)
          : const Icon(Icons.check_rounded, size: 22, color: Colors.white),
      const SizedBox(width: 10),
      const Text('Complete',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
    ]),
  );
}

/// FAB — add 적용 전/후.
Widget _fab({required bool pixel}) {
  return Container(
    width: 56,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.orbitPrimary,
      border: Border.all(color: AppPixelStyle.outline, width: 2),
      boxShadow: const [
        BoxShadow(color: AppPixelStyle.shadow, offset: AppPixelStyle.cardOffset)
      ],
    ),
    child: pixel
        ? const _PixelGlyph('add', size: 26, color: Colors.white)
        : const Icon(Icons.add_rounded, size: 26, color: Colors.white),
  );
}

/// 헤더 — settings 적용 전/후.
Widget _header({required bool pixel, String glyph = 'settingsA'}) {
  return Row(children: [
    Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
          Text('Sep 8 (Tue)', style: _label),
          const SizedBox(height: 2),
          const Text("Today's Rhythm",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: _ink)),
        ])),
    pixel
        ? _PixelGlyph(glyph, size: 26, color: _ink)
        : const Icon(Icons.settings_outlined, size: 26, color: _ink),
  ]);
}

/// 하단 네비 4칸. settingsGlyph 만 갈아 끼워 비교한다.
Widget _navStrip({required String settingsGlyph}) {
  const labels = ['Home', 'Progress', 'Routines', 'Settings'];
  final glyphs = ['navHome', 'navChart', 'navList', settingsGlyph];
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: const BoxDecoration(
      color: AppColors.orbitSurface,
      border: Border(
          top: BorderSide(color: AppPixelStyle.outline, width: 2)),
    ),
    child: Row(children: [
      for (var i = 0; i < 4; i++)
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            color: i == 3 ? AppColors.orbitHalo : null,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _PixelGlyph(glyphs[i],
                  size: 24,
                  color: i == 3 ? AppColors.orbitPrimary : _muted),
              const SizedBox(height: 5),
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: i == 3 ? AppColors.orbitPrimary : _muted)),
            ]),
          ),
        ),
    ]),
  );
}

Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12), child: Text(text, style: _heading));

Widget _beforeAfter(String caption, Widget before, Widget after) {
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(caption, style: _caption),
    const SizedBox(height: 8),
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: before),
      const SizedBox(width: 18),
      const _PixelGlyph('chevron', size: 18, color: AppColors.orbitPrimary),
      const SizedBox(width: 18),
      Expanded(child: after),
    ]),
  ]);
}

void main() {
  testWidgets('아이콘 픽셀화 시안', (tester) async {
    // Material 아이콘과 라틴 본문 폰트를 테스트 런타임에 실어 준다.
    Directory? fonts;
    for (var d = File(Platform.resolvedExecutable).parent;
        d.path != d.parent.path;
        d = d.parent) {
      final candidate = Directory('${d.path}/artifacts/material_fonts');
      if (candidate.existsSync()) {
        fonts = candidate;
        break;
      }
    }
    if (fonts == null) throw StateError('Flutter material_fonts 캐시가 필요합니다.');
    // 'Ahem'은 flutter test의 기본 폰트라 본문이 두부로 나오는 것을 막고,
    // 'Roboto'는 MaterialApp 기본 타이포그래피가 요구하는 이름이다. 둘 다 채운다.
    for (final entry in {
      'MaterialIcons': 'MaterialIcons-Regular.otf',
      'Ahem': 'Roboto-Regular.ttf',
    }.entries) {
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(
            File('${fonts.path}/${entry.value}').readAsBytesSync())));
      await loader.load();
    }
    final roboto = FontLoader('Roboto');
    for (final f in ['Roboto-Regular.ttf', 'Roboto-Bold.ttf', 'Roboto-Black.ttf']) {
      roboto.addFont(Future.value(
          ByteData.sublistView(File('${fonts.path}/$f').readAsBytesSync())));
    }
    await roboto.load();

    Directory('output/pixel-preview').createSync(recursive: true);

    // ── 시트 1: 글리프 비교 ────────────────────────────────────────────────
    final sheetKey = GlobalKey();
    await _render(
      tester,
      sheetKey,
      const Size(1140, 615),
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pixel icon proposal - 4 glyphs', style: _heading),
          const SizedBox(height: 4),
          Text('same 12x12 grid as lib/widgets/ds/pixel_nav_icon.dart', style: _caption),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _compareColumn(
                'chevron_right x4', Icons.chevron_right_rounded, 'chevron'),
            _compareColumn(
                'check x4  (v2 - fills grid)', Icons.check_rounded, 'check'),
            _compareColumn('add x3', Icons.add_rounded, 'add'),
            _compareColumn(
                'settings x2 - slider A', Icons.settings_outlined, 'sliderA'),
            _compareColumn(
                'settings x2 - slider B', Icons.settings_outlined, 'sliderB'),
          ]),
          const SizedBox(height: 26),
          Container(height: 2, width: 1076, color: AppColors.orbitBorder),
          const SizedBox(height: 20),
          Text('check - v1 (previous) vs v2, at button size', style: _caption),
          const SizedBox(height: 10),
          Row(children: [
            SizedBox(width: 300, child: _primaryButton(pixel: true, glyph: 'checkV1', size: 22)),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: _primaryButton(pixel: true, size: 26)),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: _primaryButton(pixel: false)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            SizedBox(width: 300, child: Text('v1 @22pt', style: _caption)),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: Text('v2 @26pt  (proposed)', style: _caption)),
            const SizedBox(width: 20),
            SizedBox(width: 300, child: Text('Material @22pt', style: _caption)),
          ]),
        ]),
      ),
    );
    await _capture(tester, sheetKey, 'icons-glyphs');

    // ── 시트 2: 실제 컴포넌트 적용 전/후 ──────────────────────────────────
    final contextKey = GlobalKey();
    await _render(
      tester,
      contextKey,
      const Size(1180, 760),
      Padding(
        padding: const EdgeInsets.all(32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('In context - LEFT: current   RIGHT: proposed'),
          _beforeAfter('Header . settings -> slider A',
              _header(pixel: false), _header(pixel: true, glyph: 'sliderA')),
          const SizedBox(height: 30),
          _beforeAfter('Routine row . chevron',
              _routineRow(pixel: false), _routineRow(pixel: true)),
          const SizedBox(height: 30),
          _beforeAfter('Primary button . check',
              _primaryButton(pixel: false), _primaryButton(pixel: true)),
          const SizedBox(height: 30),
          _beforeAfter(
              'FAB . add',
              Align(alignment: Alignment.centerLeft, child: _fab(pixel: false)),
              Align(alignment: Alignment.centerLeft, child: _fab(pixel: true))),
          const SizedBox(height: 30),
          _beforeAfter(
              'Header . settings -> slider B',
              _header(pixel: false),
              _header(pixel: true, glyph: 'sliderB')),
          const SizedBox(height: 30),
          _beforeAfter(
              'Bottom nav - current gear vs slider A',
              _navStrip(settingsGlyph: 'settingsA'),
              _navStrip(settingsGlyph: 'sliderA')),
        ]),
      ),
    );
    await _capture(tester, contextKey, 'icons-in-context');
  });
}

Future<void> _render(
    WidgetTester tester, GlobalKey key, Size size, Widget child) async {
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
        child: Directionality(
            textDirection: TextDirection.ltr,
            child: DefaultTextStyle(
                style: const TextStyle(color: _ink, fontFamily: 'Roboto'),
                child: child)),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  });
  File('output/pixel-preview/$name.png').writeAsBytesSync(bytes!);
}
