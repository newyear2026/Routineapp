import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models/routine_icon_id.dart';
import '../../theme/app_colors.dart';

/// 루틴 종류를 그리는 픽셀 마크. 색 사각형 대신 시안의 그림 아이콘을 쓴다.
class RoutineMark extends StatelessWidget {
  const RoutineMark({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
  });

  final RoutineIconId icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoutineMarkPainter(icon: icon, color: color),
      ),
    );
  }
}

class _RoutineMarkPainter extends CustomPainter {
  const _RoutineMarkPainter({required this.icon, required this.color});

  final RoutineIconId icon;
  final Color color;

  /// 아이콘 격자에 맞춰 계단으로 깎은 원.
  ///
  /// 칸 크기를 아이콘 셀과 같게 잡아서 원의 계단이 그림의 픽셀과 같은 줄에
  /// 떨어진다. 매끈한 원을 쓰면 픽셀 그림 뒤에서만 곡선이 돌아 어긋난다.
  static Path _disk(Size size, double cell) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final halfRows = (radius / cell).ceil();
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = -halfRows; i < halfRows; i++) {
      final y = i * cell;
      final midY = y + cell / 2;
      final half =
          (math.sqrt(math.max(0, radius * radius - midY * midY)) / cell + 0.5)
                  .floor() *
              cell;
      if (half == 0) continue;
      right.addAll([center + Offset(half, y), center + Offset(half, y + cell)]);
      left.addAll(
          [center + Offset(-half, y), center + Offset(-half, y + cell)]);
    }
    return Path()..addPolygon([...right, ...left.reversed], true);
  }

  /// 상자를 14칸으로 나눠 12칸짜리 그림을 한 칸 여백을 두고 가운데 놓는다.
  /// 12칸을 상자에 꽉 채우면 햇살·포크 끝이 원 밖으로 삐져나온다.
  static const _cells = 14;
  static const _inset = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / _cells;
    // 시안은 모든 루틴 아이콘을 연한 원형 틴트 위에 올린다. 사각형으로
    // 깔면 목록이 그림이 아니라 색 블록으로 읽힌다.
    final fill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..isAntiAlias = false;
    canvas.drawPath(_disk(size, cell), fill);

    final ink = Paint()
      ..color = AppColors.textPrimary
      ..isAntiAlias = false;
    final accent = Paint()
      ..color = color
      ..isAntiAlias = false;

    void plot(List<String> rows, Paint paint, {int dx = 0, int dy = 0}) {
      for (var y = 0; y < rows.length; y++) {
        for (var x = 0; x < rows[y].length; x++) {
          if (rows[y][x] != '#') continue;
          canvas.drawRect(
            Rect.fromLTWH(
              (x + dx + _inset) * cell,
              (y + dy + _inset) * cell,
              cell,
              cell,
            ),
            paint,
          );
        }
      }
    }

    switch (icon) {
      case RoutineIconId.sun:
        plot(const [
          '....#.#.....',
          '..#.....#...',
          '....###.....',
          '.#.#...#.#..',
          '..#.....#...',
          '#.#.....#.#.',
          '..#.....#...',
          '.#.#...#.#..',
          '....###.....',
          '..#.....#...',
          '....#.#.....',
          '............',
        ], accent);
      case RoutineIconId.dumbbell:
        plot(const [
          '............',
          '..##....##..',
          '..##....##..',
          '.####..####.',
          '.##########.',
          '..##....##..',
          '.##########.',
          '.####..####.',
          '..##....##..',
          '..##....##..',
          '............',
          '............',
        ], ink);
      case RoutineIconId.breakfast:
        plot(const [
          '............',
          '...######...',
          '..#......#..',
          '.#..####..#.',
          '.#.#....#.#.',
          '.#.#....#.#.',
          '.#..####..#.',
          '..#......#..',
          '...######...',
          '....####....',
          '............',
          '............',
        ], ink);
        plot(const [
          '..##..',
          '.#..#.',
          '.#..#.',
          '..##..',
        ], accent, dx: 4, dy: 4);
      case RoutineIconId.book:
        plot(const [
          '............',
          '..########..',
          '..#......#..',
          '..#.####.#..',
          '..#......#..',
          '..#.####.#..',
          '..#......#..',
          '..#.####.#..',
          '..#......#..',
          '..########..',
          '...##..##...',
          '............',
        ], ink);
        plot(const [
          '##',
          '##',
        ], accent, dx: 5, dy: 2);
      case RoutineIconId.bowl:
        plot(const [
          '............',
          '....#..#....',
          '...#.##.#...',
          '..#......#..',
          '.##########.',
          '.#........#.',
          '.#........#.',
          '..#......#..',
          '...######...',
          '....####....',
          '............',
          '............',
        ], ink);
      case RoutineIconId.coffee:
        plot(const [
          '............',
          '...#...#....',
          '....#.#.....',
          '...######...',
          '..#......##.',
          '..#......#.#',
          '..#......##.',
          '...######...',
          '....#..#....',
          '....####....',
          '............',
          '............',
        ], ink);
        // 잔 속은 더하기가 아니라 하트다. 십자로 그리면 구급 표시로 읽힌다.
        plot(const [
          '##.##',
          '.###.',
          '..#..',
        ], accent, dx: 3, dy: 4);
      case RoutineIconId.utensils:
        plot(const [
          '............',
          '.#.#.#..##..',
          '.#.#.#..##..',
          '.#.#.#..##..',
          '.#####...#..',
          '...#.....#..',
          '...#.....#..',
          '...#.....#..',
          '...#....##..',
          '...#...##...',
          '............',
          '............',
        ], ink);
      case RoutineIconId.moon:
        plot(const [
          '............',
          '....####....',
          '...#....#...',
          '..#......#..',
          '..#...##.#..',
          '..#..#...#..',
          '..#...##.#..',
          '...#....#...',
          '....####....',
          '..#......#..',
          '............',
          '............',
        ], accent);
      case RoutineIconId.music:
        plot(const [
          '............',
          '......####..',
          '......#..#..',
          '......#..#..',
          '......#..#..',
          '..##..#..#..',
          '.####.#..#..',
          '.####.##.#..',
          '..##...##...',
          '............',
          '............',
          '............',
        ], ink);
      case RoutineIconId.plant:
        plot(const [
          '............',
          '.....##.....',
          '...##..##...',
          '..#..##..#..',
          '...##..##...',
          '.....##.....',
          '.....##.....',
          '...######...',
          '...#....#...',
          '...######...',
          '............',
          '............',
        ], ink);
      case RoutineIconId.bag:
        plot(const [
          '............',
          '....####....',
          '...#....#...',
          '..########..',
          '..#......#..',
          '..#.####.#..',
          '..#......#..',
          '..#......#..',
          '..########..',
          '............',
          '............',
          '............',
        ], ink);
      case RoutineIconId.paw:
        plot(const [
          '............',
          '..##....##..',
          '.####..####.',
          '.####..####.',
          '..##.##.##..',
          '....####....',
          '...######...',
          '..########..',
          '...######...',
          '....####....',
          '............',
          '............',
        ], ink);
      case RoutineIconId.laptop:
        plot(const [
          '............',
          '..########..',
          '..#......#..',
          '..#.####.#..',
          '..#......#..',
          '..########..',
          '.##########.',
          '############',
          '............',
          '............',
          '............',
          '............',
        ], ink);
    }
  }

  @override
  bool shouldRepaint(covariant _RoutineMarkPainter old) =>
      old.icon != icon || old.color != color;
}
