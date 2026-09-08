import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';

/// 시간 데이터와 독립된 계단형 원판. 시간 구간은 OrbitRingPainter가 그린다.
class PixelOrbitPlate extends CustomPainter {
  const PixelOrbitPlate({this.centerOnly = false});
  final bool centerOnly;
  Path _disk(Offset center, double radius, double step) {
    final rows = (radius * 2 / step).round();
    final h = radius * 2 / rows;
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = 0; i < rows; i++) {
      final y = -radius + i * h;
      final half =
          (math.sqrt(math.max(0, radius * radius - math.pow(y + h / 2, 2))) /
                      step)
                  .round() *
              step;
      right.addAll([center + Offset(half, y), center + Offset(half, y + h)]);
      left.addAll([center + Offset(-half, y), center + Offset(-half, y + h)]);
    }
    return Path()..addPolygon([...right, ...left.reversed], true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    if (!centerOnly) {
      final plate = _disk(center, size.width * 0.48, size.width / 64);
      canvas.drawPath(
          plate.shift(AppPixelStyle.cardOffset),
          Paint()
            ..color = AppPixelStyle.shadow
            ..isAntiAlias = false);
      canvas.drawPath(
          plate,
          Paint()
            ..color = const Color(0xFFF3EDF9)
            ..isAntiAlias = false);
      canvas.drawPath(
          plate,
          Paint()
            ..color = AppPixelStyle.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..isAntiAlias = false);
      return;
    }
    final inner = _disk(center, size.width * 0.24, size.width / 64);
    canvas.drawPath(
        inner,
        Paint()
          ..color = AppColors.orbitSurface
          ..isAntiAlias = false);
    canvas.drawPath(
        inner,
        Paint()
          ..color = AppColors.orbitBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(covariant PixelOrbitPlate old) =>
      old.centerOnly != centerOnly;
}
