import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/animated_cat.dart';
import '../ds/pixel_decoration.dart';

typedef HomeTimetableBuilder = Widget Function(double size);

/// 원판 옆에 화분과, 지금 슬롯에 맞는 고양이 포즈를 둔다.
class HomeTimetableScene extends StatelessWidget {
  const HomeTimetableScene({
    super.key,
    required this.timetableBuilder,
    this.catPose = CatPose.rest,
  });

  final HomeTimetableBuilder timetableBuilder;
  final CatPose catPose;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 374.0);
          final ringSize = width * 0.76;
          return Center(
            child: SizedBox(
              key: const Key('home-timetable-scene'),
              width: width,
              height: width * 0.93,
              child: Stack(children: [
                Positioned(
                  top: width * 0.025,
                  left: (width - ringSize) / 2,
                  child: SizedBox.square(
                    key: const Key('home-timetable-ring'),
                    dimension: ringSize,
                    child: timetableBuilder(ringSize),
                  ),
                ),
                Positioned(
                    left: 0,
                    top: width * 0.08,
                    child: _Cloud(width: width * 0.14)),
                Positioned(
                    right: 0,
                    top: width * 0.16,
                    child: _Cloud(width: width * 0.14)),
                const Positioned(
                    left: 18,
                    top: 40,
                    child: _PixelStar(size: 11)),
                const Positioned(
                    right: 22,
                    top: 52,
                    child: _PixelStar(size: 12)),
                Positioned(
                  key: const Key('home-timetable-plant'),
                  left: 0,
                  bottom: width * 0.04,
                  child: const PixelDecoration(asset: 'plant', size: 54),
                ),
                Positioned(
                  key: const Key('home-timetable-cat'),
                  right: 0,
                  bottom: 0,
                  child: SizedBox(
                    width: 96,
                    height: 88,
                    child: AnimatedCat(pose: catPose),
                  ),
                ),
              ]),
            ),
          );
        },
      );
}

class _Cloud extends StatelessWidget {
  const _Cloud({required this.width});
  final double width;
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
            child: CustomPaint(
          size: Size(width, width * 0.5),
          painter: const _CloudPainter(),
        )),
      );
}

class _CloudPainter extends CustomPainter {
  const _CloudPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Path()
      ..addPolygon([
        Offset(0, size.height),
        Offset(0, size.height * .65),
        Offset(size.width * .18, size.height * .65),
        Offset(size.width * .18, size.height * .30),
        Offset(size.width * .35, size.height * .30),
        Offset(size.width * .35, 0),
        Offset(size.width * .58, 0),
        Offset(size.width * .58, size.height * .30),
        Offset(size.width * .76, size.height * .30),
        Offset(size.width * .76, size.height * .65),
        Offset(size.width, size.height * .65),
        Offset(size.width, size.height),
      ], true);
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFFFFCF4)
          ..isAntiAlias = false);
    canvas.drawPath(
        p,
        Paint()
          ..color = const Color(0xFFC7B79C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}

class _PixelStar extends StatelessWidget {
  const _PixelStar({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size.square(size),
            painter: const _PixelStarPainter(),
          ),
        ),
      );
}

class _PixelStarPainter extends CustomPainter {
  const _PixelStarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 5;
    final paint = Paint()
      ..color = const Color(0xFFA98BEC)
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(unit * 2, 0, unit, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, unit * 2, size.width, unit), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelStarPainter oldDelegate) => false;
}
