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

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 12;
    final fill = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..isAntiAlias = false;
    canvas.drawRect(Offset.zero & size, fill);

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
            Rect.fromLTWH((x + dx) * cell, (y + dy) * cell, cell, cell),
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
        plot(const [
          '.#.',
          '###',
          '.#.',
        ], accent, dx: 4, dy: 5);
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
