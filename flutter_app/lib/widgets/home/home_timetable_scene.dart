import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/pixel_decoration.dart';
import '../store/character_pack_scope.dart';

typedef HomeTimetableBuilder = Widget Function(double size);

/// 원판 옆에 화분을 둔다. 고양이는 홈 첫 카드(`HomeFocusCard`)로 옮겼다 —
/// 지금 상태를 말하는 캐릭터가 상태 카드 안에 있어야 위젯과 같은 모습이 된다.
class HomeTimetableScene extends StatelessWidget {
  const HomeTimetableScene({
    super.key,
    required this.timetableBuilder,
  });

  final HomeTimetableBuilder timetableBuilder;

  @override
  Widget build(BuildContext context) {
    final garden = CharacterPackScope.currentOf(context).id == 'poodle_garden';
    final stargazer =
        CharacterPackScope.currentOf(context).id == 'cat_stargazer';
    final rabbit = CharacterPackScope.currentOf(context).id == 'rabbit_postman';
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 374.0);
        // 첫 카드가 지금 할 일을 말한다. 원판은 하루 흐름을 보여 주는 두 번째
        // 자리라, 완료·나중에·건너뛰기가 스크롤 없이 들어오는 크기로 둔다.
        final ringSize = width * 0.63;
        final decoSize = garden
            ? math.min(width * 0.19, 56.0)
            : math.min(width * 0.23, 68.0);
        return Center(
          child: SizedBox(
            key: const Key('home-timetable-scene'),
            width: width,
            height: width * 0.66,
            child: Stack(clipBehavior: Clip.none, children: [
              if (!garden && !stargazer && !rabbit)
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
              if (!stargazer && !rabbit)
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
              if (stargazer) ...[
                Positioned(
                  left: width * 0.01,
                  bottom: 0,
                  child: PixelDecoration(
                      asset: 'stargazer-telescope', size: decoSize),
                ),
                Positioned(
                  right: width * 0.01,
                  top: width * 0.03,
                  child: const PixelDecoration(
                      asset: 'stargazer-meteor', size: 46),
                ),
                Positioned(
                  right: width * 0.01,
                  bottom: 0,
                  child: const PixelDecoration(
                      asset: 'stargazer-celestial-globe', size: 46),
                ),
              ],
              if (rabbit) ...[
                Positioned(
                  left: width * 0.01,
                  bottom: 0,
                  child: PixelDecoration(
                    asset: 'rabbit-letter',
                    size: decoSize,
                  ),
                ),
                Positioned(
                  right: width * 0.01,
                  top: width * 0.03,
                  child: const PixelDecoration(
                    asset: 'rabbit-carrot-stamp',
                    size: 42,
                  ),
                ),
                Positioned(
                  right: width * 0.01,
                  bottom: 0,
                  child: const PixelDecoration(
                    asset: 'rabbit-satchel',
                    size: 44,
                  ),
                ),
              ],
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
            ]),
          ),
        );
      },
    );
  }
}
