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
          final catWidth = math.min(width * 0.39, 132.0);
          final plantSize = math.min(width * 0.23, 68.0);
          return Center(
            child: SizedBox(
              key: const Key('home-timetable-scene'),
              width: width,
              height: width * 0.89,
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/decorations/home-sky.png',
                      fit: BoxFit.fill,
                      filterQuality: FilterQuality.none,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
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
                  key: const Key('home-timetable-plant'),
                  left: width * 0.08,
                  bottom: 0,
                  child: PixelDecoration(asset: 'plant', size: plantSize),
                ),
                Positioned(
                  key: const Key('home-timetable-cat'),
                  right: -width * 0.065,
                  bottom: 0,
                  child: SizedBox(
                    width: catWidth,
                    height: catWidth * 0.8,
                    child: AnimatedCat(pose: catPose),
                  ),
                ),
              ]),
            ),
          );
        },
      );
}
