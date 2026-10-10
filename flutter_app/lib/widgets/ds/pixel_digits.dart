import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 픽셀 격자로 직접 그린 숫자 — 시계처럼 한눈에 읽혀야 하는 큰 숫자용.
///
/// Pixelify Sans 700은 3의 윗부분이 둥글게 닫혀 8처럼, 5가 S처럼 읽혔다
/// («13:31»이 «18:81»). 폰트를 바꾸는 대신 헷갈리는 모양을 격자에서 직접 잡는다.
/// - 3은 윗변이 평평하다 (8과 구분)
/// - 5는 왼쪽 위가 직각이다 (S·6과 구분)
/// - 0은 가운데 가로획이 없다 (8과 구분)
///
/// 한 칸 크기를 기기 픽셀에 맞춰 내려 잡아 어떤 크기에서도 흐리지 않다.
/// 그래서 [FittedBox]처럼 크기를 바꾸는 부모 아래에 두지 않고 [maxWidth]로 맞춘다.
/// 세로획은 두 칸 두께로 그려 앱의 굵은 픽셀 인상을 지킨다.
class PixelDigits extends StatelessWidget {
  const PixelDigits(
    this.text, {
    super.key,
    required this.height,
    this.maxWidth,
    this.color = AppColors.textStrong,
    this.semanticsLabel,
  });

  /// 그릴 글자. [PixelDigitGlyphs.supports]가 받는 글자만 쓴다.
  final String text;

  /// 글자 높이(논리 픽셀). 실제 높이는 기기 픽셀 격자에 맞춰 조금 작아질 수 있다.
  final double height;

  /// 폭 상한. 넘치면 칸을 줄인다 — 부모가 늘이거나 줄이면 격자가 흐려진다.
  final double? maxWidth;
  final Color color;

  /// 스크린 리더가 읽을 말. null이면 [text]를 그대로 읽는다.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 1;
    final columns = PixelDigitGlyphs.columnsOf(text);
    final byHeight = height / PixelDigitGlyphs.rows;
    final byWidth =
        maxWidth == null || columns == 0 ? byHeight : maxWidth! / columns;
    final cell = PixelDigitGlyphs.snap(
      byWidth < byHeight ? byWidth : byHeight,
      dpr,
    );
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: CustomPaint(
        size: Size(columns * cell, PixelDigitGlyphs.rows * cell),
        painter: _PixelDigitsPainter(text: text, cell: cell, color: color),
      ),
    );
  }
}

/// 5×7 격자 글꼴. 테스트가 헷갈리는 짝이 서로 다른지 이 표로 지킨다.
abstract final class PixelDigitGlyphs {
  static const rows = 7;

  /// 켜진 칸마다 오른쪽 한 칸을 더 칠한다 — 세로획이 두 칸 두께가 된다.
  static const boldExtra = 1;

  /// 글자 사이 빈 칸 수.
  static const gap = 1;

  static const glyphs = <String, List<String>>{
    '0': ['01110', '10001', '10001', '10001', '10001', '10001', '01110'],
    '1': ['00100', '01100', '00100', '00100', '00100', '00100', '01110'],
    '2': ['01110', '10001', '00001', '00010', '00100', '01000', '11111'],
    '3': ['11111', '00010', '00100', '00010', '00001', '10001', '01110'],
    '4': ['00010', '00110', '01010', '10010', '11111', '00010', '00010'],
    '5': ['11111', '10000', '11110', '00001', '00001', '10001', '01110'],
    '6': ['00110', '01000', '10000', '11110', '10001', '10001', '01110'],
    '7': ['11111', '00001', '00010', '00100', '01000', '01000', '01000'],
    '8': ['01110', '10001', '10001', '01110', '10001', '10001', '01110'],
    '9': ['01110', '10001', '10001', '01111', '00001', '00010', '01100'],
    ':': ['0', '0', '1', '0', '1', '0', '0'],
    '/': ['0001', '0001', '0010', '0010', '0100', '0100', '1000'],
    '%': ['11001', '11010', '00010', '00100', '01000', '01011', '10011'],
    ' ': ['0', '0', '0', '0', '0', '0', '0'],
  };

  static bool supports(String text) =>
      text.isNotEmpty && text.split('').every(glyphs.containsKey);

  /// 글자 하나가 차지하는 칸 수 (굵게 그린 폭 포함).
  static int widthOf(String char) => glyphs[char]![0].length + boldExtra;

  static int columnsOf(String text) {
    var columns = 0;
    for (final char in text.split('')) {
      if (!glyphs.containsKey(char)) continue;
      if (columns > 0) columns += gap;
      columns += widthOf(char);
    }
    return columns;
  }

  /// [text]를 [origin]에서부터 칸 크기 [cell]로 그린다. 원판 눈금처럼
  /// 위젯이 아닌 페인터 안에서 숫자를 그릴 때도 같은 격자를 쓴다.
  static void paint(
    Canvas canvas,
    String text, {
    required Offset origin,
    required double cell,
    required Color color,
  }) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    var column = 0;
    for (final char in text.split('')) {
      final glyph = glyphs[char];
      if (glyph == null) continue;
      for (var row = 0; row < glyph.length; row++) {
        final line = glyph[row];
        for (var x = 0; x < line.length; x++) {
          if (line[x] != '1') continue;
          canvas.drawRect(
            Rect.fromLTWH(
              origin.dx + (column + x) * cell,
              origin.dy + row * cell,
              cell * (1 + boldExtra),
              cell,
            ),
            paint,
          );
        }
      }
      column += widthOf(char) + gap;
    }
  }

  /// 칸 크기를 기기 픽셀 단위로 내려 잡는다. 칸 경계가 픽셀 사이에 걸리면 흐려진다.
  static double snap(double cell, double devicePixelRatio) {
    final physical = (cell * devicePixelRatio).floorToDouble();
    return (physical < 1 ? 1 : physical) / devicePixelRatio;
  }
}

class _PixelDigitsPainter extends CustomPainter {
  const _PixelDigitsPainter({
    required this.text,
    required this.cell,
    required this.color,
  });

  final String text;
  final double cell;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => PixelDigitGlyphs.paint(
        canvas,
        text,
        origin: Offset.zero,
        cell: cell,
        color: color,
      );

  @override
  bool shouldRepaint(_PixelDigitsPainter old) =>
      old.text != text || old.cell != cell || old.color != color;
}
