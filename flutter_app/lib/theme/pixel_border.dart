import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 모서리를 계단식으로 깎은 사각형.
///
/// 라운드는 곡선이라 픽셀과 어긋나고, 완전한 직각은 딱딱하다. 모서리를
/// [steps]칸 × [step]px 만큼 대각으로 잘라 내면 곡률 없이도 부드러워진다.
///
/// [ShapeDecoration]·[ThemeData]의 shape 자리에 그대로 넣을 수 있고,
/// 그림자도 이 경로를 따라가므로 카드와 그림자의 모서리가 어긋나지 않는다.
class PixelBorder extends OutlinedBorder {
  const PixelBorder({
    super.side = BorderSide.none,
    this.step = 4,
    this.steps = 2,
  });

  /// 계단 한 칸의 크기(px).
  final double step;

  /// 모서리를 몇 칸에 걸쳐 깎을지.
  final int steps;

  /// 잘라 낼 총 길이. 짧은 변의 절반을 넘지 않도록 [_cut]에서 다시 조인다.
  double get _corner => step * steps;

  double _cut(Rect rect) =>
      math.min(_corner, math.min(rect.width, rect.height) / 2);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.strokeInset);

  @override
  PixelBorder copyWith({BorderSide? side, double? step, int? steps}) =>
      PixelBorder(
        side: side ?? this.side,
        step: step ?? this.step,
        steps: steps ?? this.steps,
      );

  @override
  ShapeBorder scale(double t) =>
      PixelBorder(side: side.scale(t), step: step * t, steps: steps);

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is PixelBorder && a.steps == steps) {
      return PixelBorder(
        side: BorderSide.lerp(a.side, side, t),
        step: _lerp(a.step, step, t),
        steps: steps,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is PixelBorder && b.steps == steps) {
      return PixelBorder(
        side: BorderSide.lerp(side, b.side, t),
        step: _lerp(step, b.step, t),
        steps: steps,
      );
    }
    return super.lerpTo(b, t);
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      insetPath(rect, side.strokeInset);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _build(rect, _cut(rect));

  /// 이 도형과 **평행하게** [inset] 만큼 안으로 들어간 경로.
  ///
  /// 사각형만 줄이면 45° 모서리는 평행해지지 않는다. 변은 [inset] 만큼
  /// 들어가는데 대각선은 그 절반쯤(inset/√2)밖에 안 들어가서, 모서리에서만
  /// 간격이 벌어진다. 잘라 내는 길이를 inset × (2 − √2) 만큼 함께 줄여야
  /// 네 변과 네 모서리의 간격이 같아진다.
  Path insetPath(Rect rect, double inset) {
    if (inset <= 0) return _build(rect, _cut(rect));
    final inner = rect.deflate(inset);
    if (inner.isEmpty) return Path();
    final corner = _cut(rect) - inset * (2 - math.sqrt2);
    return _build(inner, math.max(0, math.min(corner, _cut(inner))));
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width == 0) return;
    canvas.drawPath(
      Path.combine(
          PathOperation.difference, getOuterPath(rect), getInnerPath(rect)),
      Paint()
        ..color = side.color
        ..isAntiAlias = false,
    );
  }

  /// 시계 방향으로 네 변을 잇고, 모서리마다 [c] 길이의 계단을 놓는다.
  Path _build(Rect rect, double c) {
    if (rect.isEmpty) return Path();
    if (c <= 0) return Path()..addRect(rect);
    final unit = c / steps;
    final path = Path()..moveTo(rect.left + c, rect.top);

    path.lineTo(rect.right - c, rect.top);
    for (var i = 1; i <= steps; i++) {
      path.lineTo(rect.right - c + i * unit, rect.top + (i - 1) * unit);
      path.lineTo(rect.right - c + i * unit, rect.top + i * unit);
    }

    path.lineTo(rect.right, rect.bottom - c);
    for (var i = 1; i <= steps; i++) {
      path.lineTo(rect.right - (i - 1) * unit, rect.bottom - c + i * unit);
      path.lineTo(rect.right - i * unit, rect.bottom - c + i * unit);
    }

    path.lineTo(rect.left + c, rect.bottom);
    for (var i = 1; i <= steps; i++) {
      path.lineTo(rect.left + c - i * unit, rect.bottom - (i - 1) * unit);
      path.lineTo(rect.left + c - i * unit, rect.bottom - i * unit);
    }

    path.lineTo(rect.left, rect.top + c);
    for (var i = 1; i <= steps; i++) {
      path.lineTo(rect.left + (i - 1) * unit, rect.top + c - i * unit);
      path.lineTo(rect.left + i * unit, rect.top + c - i * unit);
    }

    return path..close();
  }

  @override
  bool operator ==(Object other) =>
      other is PixelBorder &&
      other.side == side &&
      other.step == step &&
      other.steps == steps;

  @override
  int get hashCode => Object.hash(side, step, steps);
}

double _lerp(double a, double b, double t) => a + (b - a) * t;
