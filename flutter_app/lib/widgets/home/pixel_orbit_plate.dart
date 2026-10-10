import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';

/// 시간 데이터와 독립된 계단형 원판. 시간 구간은 OrbitRingPainter가 그린다.
class PixelOrbitPlate extends CustomPainter {
  const PixelOrbitPlate({
    this.centerOnly = false,
    this.step,
    this.dialColor = AppColors.dialSurface,
    this.surfaceColor = AppColors.orbitSurface,
  });
  final bool centerOnly;
  final Color dialColor;
  final Color surfaceColor;

  /// 계단 한 칸(px). 비우면 홈 크기에 맞춘 size/146을 쓴다. 작은 원판은
  /// 그 값이 1px 아래로 내려가 계단이 사라지므로 직접 준다.
  final double? step;
  Path _disk(Offset center, double radius, double step) {
    // 양 축에 같은 격자를 써서 네 방향의 곡률과 계단 크기를 맞춘다.
    final halfRows = (radius / step).ceil();
    final right = <Offset>[];
    final left = <Offset>[];
    for (var i = -halfRows; i < halfRows; i++) {
      final y = i * step;
      final midY = y + step / 2;
      final half =
          (math.sqrt(math.max(0, radius * radius - midY * midY)) / step + 0.5)
                  .floor() *
              step;
      if (half == 0) continue;
      right.addAll([center + Offset(half, y), center + Offset(half, y + step)]);
      left.addAll(
          [center + Offset(-half, y), center + Offset(-half, y + step)]);
    }
    return Path()..addPolygon([...right, ...left.reversed], true);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final step = this.step ?? size.width / 146;
    if (!centerOnly) {
      final plate = _disk(center, size.width * 0.48, step);
      canvas.drawPath(
          plate.shift(AppPixelStyle.cardOffset),
          Paint()
            ..color = AppPixelStyle.shadow
            ..isAntiAlias = false);
      canvas.drawPath(
          plate,
          Paint()
            ..color = dialColor
            ..isAntiAlias = false);
      canvas.drawPath(
          plate,
          Paint()
            ..color = AppPixelStyle.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..isAntiAlias = false);
      // 시간 링 안쪽은 밝은 시계 면, 링 둘레에는 가는 흰 테두리.
      canvas.drawPath(
        _disk(center, size.width * 0.417, step),
        Paint()
          ..color = Colors.white
          ..isAntiAlias = false,
      );
      canvas.drawPath(
        _disk(center, size.width * 0.373, step),
        Paint()
          ..color = surfaceColor
          ..isAntiAlias = false,
      );
      return;
    }
    final inner = _disk(center, size.width * 0.215, step);
    canvas.drawPath(
        inner,
        Paint()
          ..color = surfaceColor
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
      old.centerOnly != centerOnly ||
      old.step != step ||
      old.dialColor != dialColor ||
      old.surfaceColor != surfaceColor;
}
