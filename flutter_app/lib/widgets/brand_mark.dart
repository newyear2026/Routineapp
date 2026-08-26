import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 브랜드 마크 — 하루한바퀴 / DayRound / Vuelta al Día.
///
/// 닫힌 궤도 하나가 하루를 한 바퀴 돈다. 궤도 위에 해와 달이 얹혀 낮과 밤을
/// 표시하고, 작은 알약 두 개가 그날의 루틴 블록을 뜻한다.
///
/// 좌표계는 앱의 원형 시간표([OrbitRingPainter])와 같다 — 0도가 12시 방향,
/// 시계 방향. 다만 해·달의 각도는 시각을 가리키는 값이 아니라 구도를 위해
/// 고정한 값이다. 시간에 따라 움직이지 않는다.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 200});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _BrandMarkPainter(), isComplex: false),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  const _BrandMarkPainter();

  static const Color _navy = Color(0xFF2B3A63);
  static const Color _sun = Color(0xFFFBBE12);
  static const Color _moon = Color(0xFFF9564E);
  static const Color _slate = Color(0xFF97A1AE);

  static const double _sunDeg = 52;
  static const double _moonDeg = 233;

  static double _rad(double deg) => (deg - 90) * math.pi / 180;

  Offset _at(Offset c, double r, double deg) => Offset(
        c.dx + math.cos(_rad(deg)) * r,
        c.dy + math.sin(_rad(deg)) * r,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final center = Offset(s / 2, s / 2);
    final radius = s * 0.355;
    final stroke = s * 0.038;
    final orbR = s * 0.056;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // 궤도 — 해와 달이 앉을 자리를 비워 둔 두 개의 호
    final ring = Paint()
      ..color = _navy
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (final (from, to) in const [(70.0, 218.0), (248.0, 400.0)]) {
      canvas.drawArc(rect, _rad(from), _rad(to) - _rad(from), false, ring);
    }

    // 루틴 블록 — 궤도 안에 박힌 알약
    final pill = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.024
      ..strokeCap = StrokeCap.round;
    for (final (deg, color) in const [(339.0, _sun), (162.0, _slate)]) {
      canvas.drawArc(
        rect,
        _rad(deg - 5),
        _rad(deg + 5) - _rad(deg - 5),
        false,
        pill..color = color,
      );
    }

    canvas.drawCircle(
      _at(center, radius, _sunDeg),
      orbR,
      Paint()..color = _sun,
    );

    _paintCrescent(canvas, _at(center, radius, _moonDeg), orbR * 1.34);
  }

  /// 초승달 — 원 두 개의 even-odd 차집합. 배경을 덮어 파내지 않으므로
  /// 어떤 배경 위에 올려도 궤도에 구멍이 나지 않는다.
  void _paintCrescent(Canvas canvas, Offset at, double r) {
    final bite = Offset(
      at.dx + math.cos(_rad(53)) * r * 0.52,
      at.dy + math.sin(_rad(53)) * r * 0.52,
    );
    // evenOdd로 겹치면 바깥 원을 벗어난 안쪽 원까지 칠해져, 초승달이 아니라
    // 구멍 뚫린 원이 된다. 차집합이어야 뿔이 열린다.
    final path = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: at, radius: r)),
      Path()..addOval(Rect.fromCircle(center: bite, radius: r * 0.86)),
    );
    canvas.drawPath(path, Paint()..color = _moon);
  }

  @override
  bool shouldRepaint(covariant _BrandMarkPainter oldDelegate) => false;
}
