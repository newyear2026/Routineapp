import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../ds/animated_cat.dart';

typedef HomeTimetableBuilder = Widget Function(double size);

/// 중앙 시간표 주변의 빈 모서리에 장식을 배치한다.
class HomeTimetableScene extends StatelessWidget {
  const HomeTimetableScene(
      {super.key, required this.timetableBuilder, this.pose = CatPose.idle});
  final CatPose pose;
  final HomeTimetableBuilder timetableBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 374.0);
          final ringSize = width * 0.76;
          final catWidth = width * 0.29;
          final catHeight = width * 0.185;
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
                  left: 2,
                  top: width * 0.045,
                  child: IgnorePointer(
                      child: ExcludeSemantics(
                          child: CustomPaint(
                    key: const Key('home-timetable-moon'),
                    size: Size.square(width * 0.12),
                    painter: const _PixelMoonPainter(),
                  ))),
                ),
                Positioned(
                    left: 0,
                    top: width * 0.22,
                    child: _Cloud(width: width * 0.14)),
                Positioned(
                    right: 0,
                    top: width * 0.13,
                    child: _Cloud(width: width * 0.14)),
                Positioned(
                    left: 0,
                    top: width * 0.65,
                    child: _Cloud(width: width * 0.15)),
                Positioned(
                    left: width * 0.18,
                    top: width * 0.06,
                    child: const _PixelStar(
                        size: 11, color: AppColors.orbitAccent)),
                Positioned(
                    right: width * 0.12,
                    top: width * 0.04,
                    child: const _PixelStar(
                        size: 14, color: AppColors.orbitAccent)),
                Positioned(
                    right: 0,
                    top: width * 0.30,
                    child: const _PixelStar(
                        size: 12, color: AppColors.orbitAccent)),
                Positioned(
                    left: 0,
                    top: width * 0.56,
                    child: const _PixelStar(
                        size: 12, color: AppColors.orbitAccent)),
                Positioned(
                    left: width * 0.19,
                    bottom: width * 0.08,
                    child: const _PixelStar(
                        size: 11, color: AppColors.orbitAccent)),
                Positioned(
                  right: 2,
                  bottom: 0,
                  child: SizedBox(
                    key: const Key('home-timetable-character-rail'),
                    width: catWidth,
                    height: catHeight,
                    child: AnimatedCat(
                        key: const Key('home-timetable-cat'), pose: pose),
                  ),
                ),
                if (pose == CatPose.rest)
                  Positioned(
                      right: 6,
                      bottom: catHeight + 4,
                      child: const IgnorePointer(
                          child: ExcludeSemantics(
                              child: Text(
                        'z Z',
                        style: TextStyle(
                            fontFamily: 'PixelifySans',
                            fontSize: 16,
                            color: AppColors.textPrimary),
                      )))),
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
          ..color = AppColors.decorationCloud
          ..isAntiAlias = false);
  }

  @override
  bool shouldRepaint(_CloudPainter oldDelegate) => false;
}

class _PixelStar extends StatelessWidget {
  const _PixelStar({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(
          child: CustomPaint(
            size: Size.square(size),
            painter: _PixelStarPainter(color),
          ),
        ),
      );
}

class _PixelStarPainter extends CustomPainter {
  const _PixelStarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 5;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    canvas.drawRect(Rect.fromLTWH(unit * 2, 0, unit, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(0, unit * 2, size.width, unit), paint);
  }

  @override
  bool shouldRepaint(covariant _PixelStarPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PixelMoonPainter extends CustomPainter {
  const _PixelMoonPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final moon = Path()
      ..addPolygon(
        [
          Offset(w * 0.38, 0),
          Offset(w * 0.72, 0),
          Offset(w * 0.72, h * 0.12),
          Offset(w * 0.56, h * 0.12),
          Offset(w * 0.56, h * 0.25),
          Offset(w * 0.47, h * 0.25),
          Offset(w * 0.47, h * 0.63),
          Offset(w * 0.56, h * 0.63),
          Offset(w * 0.56, h * 0.75),
          Offset(w * 0.72, h * 0.75),
          Offset(w * 0.72, h * 0.88),
          Offset(w * 0.91, h * 0.88),
          Offset(w * 0.91, h),
          Offset(w * 0.47, h),
          Offset(w * 0.47, h * 0.88),
          Offset(w * 0.25, h * 0.88),
          Offset(w * 0.25, h * 0.75),
          Offset(w * 0.13, h * 0.75),
          Offset(w * 0.13, h * 0.5),
          Offset(0, h * 0.5),
          Offset(0, h * 0.25),
          Offset(w * 0.13, h * 0.25),
          Offset(w * 0.13, h * 0.12),
          Offset(w * 0.38, h * 0.12),
        ],
        true,
      );
    canvas.drawPath(
      moon,
      Paint()
        ..color = AppColors.orbitAccent
        ..isAntiAlias = false,
    );
  }

  @override
  bool shouldRepaint(covariant _PixelMoonPainter oldDelegate) => false;
}
