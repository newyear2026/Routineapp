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
