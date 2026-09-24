import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/animated_cat.dart';
import '../ds/pixel_decoration.dart';
import '../store/character_pack_scope.dart';

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
  Widget build(BuildContext context) {
    final garden = CharacterPackScope.currentOf(context).id == 'poodle_garden';
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 374.0);
        final ringSize = width * 0.76;
        final catWidth = math.min(width * 0.39, 132.0);
        final decoSize = garden
            ? math.min(width * 0.19, 56.0)
            : math.min(width * 0.23, 68.0);
        return Center(
          child: SizedBox(
            key: const Key('home-timetable-scene'),
            width: width,
            height: width * 0.89,
            child: Stack(clipBehavior: Clip.none, children: [
              if (!garden)
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
                key: Key(garden
                    ? 'home-timetable-watering-can'
                    : 'home-timetable-plant'),
                left: garden ? 0 : width * 0.08,
                bottom: garden ? -6 : 0,
                child: PixelDecoration(
                  asset: garden ? 'garden-watering-can' : 'plant',
                  size: decoSize,
                ),
              ),
              if (garden) ...[
                Positioned(
                  left: width * 0.01,
                  top: width * 0.17,
                  child: const GardenLeaf(
                    key: Key('home-garden-leaf-left'),
                    size: 27,
                    mirror: true,
                  ),
                ),
                Positioned(
                  right: width * 0.005,
                  top: width * 0.25,
                  child: const GardenLeaf(
                    key: Key('home-garden-leaf-right'),
                    size: 25,
                    angle: -0.3,
                  ),
                ),
                Positioned(
                  left: width * 0.19,
                  bottom: width * 0.12,
                  child: const GardenLeaf(size: 20, angle: 0.5),
                ),
                Positioned(
                  right: width * 0.01,
                  bottom: width * 0.34,
                  child: const GardenLeaf(size: 20, mirror: true),
                ),
              ],
              if (garden)
                Positioned(
                  right: width * 0.04,
                  top: width * 0.08,
                  child: const PixelDecoration(
                    asset: 'garden-daisy',
                    size: 42,
                  ),
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
}
