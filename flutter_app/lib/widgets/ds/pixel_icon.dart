import 'package:flutter/material.dart';

/// 12×12 그리드에 직접 찍어 그리는 아이콘.
///
/// 픽셀 스타일은 매끄러운 곡선 하나가 섞이면 전체가 어색해진다. 화면에 자주
/// 나오는 글리프부터 이 그리드로 옮겨 하단 내비게이션과 결을 맞춘다.
/// 곡선이 많은 글리프(종·스피커·번역 등)는 12×12에서 뭉개지므로 Material을
/// 그대로 둔다 — [AppIcon] 이 그 판정을 대신한다.
enum PixelGlyph {
  home,
  progress,
  routines,

  /// 톱니바퀴는 12×12에서 이가 뭉쳐 조준경처럼 읽힌다. 픽셀 그리드가 강한
  /// 수평선으로 바꿔 같은 '설정' 의미를 전달한다.
  settings,

  /// 하단 탭 전용 — 다른 화면의 픽셀 아이콘은 그대로 유지한다.
  navHome,
  navProgress,
  navRoutines,
  navSettings,

  chevronLeft,
  chevronRight,
  check,
  add,
}

extension PixelGlyphMetrics on PixelGlyph {
  /// 같은 `size` 값에서도 글리프마다 실제로 칠해지는 면적이 다르다.
  ///
  /// 체크는 세로획이 없어 12행 중 8행만 쓰므로 Material 체크와 나란히 두면
  /// 눈에 띄게 작아 보인다. 그리는 상자만 키워 시각적 크기를 맞춘다.
  double get opticalScale => switch (this) {
        PixelGlyph.check => 1.4,
        _ => 1.0,
      };
}

const _patterns = <PixelGlyph, List<String>>{
  PixelGlyph.navHome: [
    '.....##.....',
    '....####....',
    '...##..##...',
    '..##....##..',
    '.##......##.',
    '##........##',
    '..########..',
    '..#......#..',
    '..#..##..#..',
    '..#..##..#..',
    '..########..',
    '............',
  ],
  PixelGlyph.navProgress: [
    '............',
    '...######...',
    '..##....##..',
    '.##......##.',
    '.##......##.',
    '.##...#####.',
    '.##...#####.',
    '.##...#####.',
    '..##..####..',
    '...######...',
    '............',
    '............',
  ],
  PixelGlyph.navRoutines: [
    '.###..#####.',
    '.#.#..#####.',
    '.###........',
    '............',
    '.###..#####.',
    '.#.#..#####.',
    '.###........',
    '............',
    '.###..#####.',
    '.#.#..#####.',
    '.###........',
    '............',
  ],
  PixelGlyph.navSettings: [
    '.......##...',
    '.##########.',
    '.......##...',
    '............',
    '...##.......',
    '.##########.',
    '...##.......',
    '............',
    '......##....',
    '.##########.',
    '......##....',
    '............',
  ],
  PixelGlyph.home: [
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
  PixelGlyph.progress: [
    '............',
    '...######...',
    '..##....##..',
    '.##......##.',
    '.##...#..##.',
    '.##...##.##.',
    '.##....#.##.',
    '.##......##.',
    '..##....##..',
    '...######...',
    '............',
    '............',
  ],
  PixelGlyph.routines: [
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
  PixelGlyph.settings: [
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
  PixelGlyph.chevronLeft: [
    '............',
    '.......##...',
    '......##....',
    '.....##.....',
    '....##......',
    '...##.......',
    '...##.......',
    '....##......',
    '.....##.....',
    '......##....',
    '.......##...',
    '............',
  ],
  PixelGlyph.chevronRight: [
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
  PixelGlyph.check: [
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
  PixelGlyph.add: [
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
};

/// Material 아이콘 중 픽셀 글리프로 대체할 것들.
///
/// 같은 뜻의 변종(`check` / `check_rounded`)은 하나로 모은다.
PixelGlyph? pixelGlyphFor(IconData icon) {
  if (icon == Icons.chevron_right_rounded ||
      icon == Icons.chevron_right ||
      icon == Icons.arrow_forward_ios_rounded) {
    return PixelGlyph.chevronRight;
  }
  if (icon == Icons.chevron_left_rounded ||
      icon == Icons.chevron_left ||
      icon == Icons.arrow_back_ios_rounded) {
    return PixelGlyph.chevronLeft;
  }
  if (icon == Icons.check_rounded || icon == Icons.check) {
    return PixelGlyph.check;
  }
  if (icon == Icons.add_rounded || icon == Icons.add) return PixelGlyph.add;
  if (icon == Icons.settings_outlined ||
      icon == Icons.settings ||
      icon == Icons.tune_rounded) {
    return PixelGlyph.settings;
  }
  return null;
}

class PixelIcon extends StatelessWidget {
  const PixelIcon(this.glyph,
      {super.key, required this.size, required this.color});

  final PixelGlyph glyph;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
            size: Size(size, size),
            painter: _PixelIconPainter(_patterns[glyph]!, color)),
      );
}

/// [Icon]을 대신 두는 자리. 픽셀 글리프가 있으면 그것을, 없으면 Material을 그린다.
///
/// 호출부는 지금까지처럼 [IconData]만 넘기면 되고, 어떤 아이콘을 픽셀로
/// 그릴지는 [pixelGlyphFor] 한 곳에서만 결정한다.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color});

  final IconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final glyph = pixelGlyphFor(icon);
    if (glyph == null) return Icon(icon, size: size, color: color);
    final theme = IconTheme.of(context);
    final resolved = size ?? theme.size ?? 24;
    return PixelIcon(
      glyph,
      size: resolved * glyph.opticalScale,
      color: color ?? theme.color ?? Colors.black,
    );
  }
}

class _PixelIconPainter extends CustomPainter {
  const _PixelIconPainter(this.pattern, this.color);

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
  bool shouldRepaint(covariant _PixelIconPainter old) =>
      old.pattern != pattern || old.color != color;
}
