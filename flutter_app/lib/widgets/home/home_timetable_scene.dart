import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/pixel_decoration.dart';
import '../../theme/pack_skin.dart';
import '../store/character_pack_scope.dart';

typedef HomeTimetableBuilder = Widget Function(double size);

/// 원판 둘레에 팩의 장면([HomeSceneSpec])을 둔다. 고양이는 홈 첫
/// 카드(`HomeFocusCard`)로 옮겼다 —
/// 지금 상태를 말하는 캐릭터가 상태 카드 안에 있어야 위젯과 같은 모습이 된다.
class HomeTimetableScene extends StatelessWidget {
  const HomeTimetableScene({
    super.key,
    required this.timetableBuilder,
  });

  final HomeTimetableBuilder timetableBuilder;

  @override
  Widget build(BuildContext context) {
    final scene = CharacterPackScope.skinOf(context).homeScene;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 374.0);
        // 첫 카드가 지금 할 일을 말한다. 원판은 하루 흐름을 보여 주는 두 번째
        // 자리라, 완료·나중에·건너뛰기가 스크롤 없이 들어오는 크기로 둔다.
        final ringSize = width * 0.63;
        final leadSize = scene.leadSize(width);
        return Center(
          child: SizedBox(
            key: const Key('home-timetable-scene'),
            width: width,
            height: width * 0.66,
            child: Stack(clipBehavior: Clip.none, children: [
              if (scene.backdrop case final backdrop?)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.asset(
                      backdrop,
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
              for (final prop in scene.props)
                Positioned(
                  // 데코는 자리에, 잎은 잎에 키를 단다 — 테스트가 찾는 모양 그대로다.
                  key: prop.asset != null && prop.key != null
                      ? Key(prop.key!)
                      : null,
                  left: prop.left?.resolve(width),
                  top: prop.top?.resolve(width),
                  right: prop.right?.resolve(width),
                  bottom: prop.bottom?.resolve(width),
                  child: _SceneProp(prop: prop, leadSize: leadSize),
                ),
            ]),
          ),
        );
      },
    );
  }
}

class _SceneProp extends StatelessWidget {
  const _SceneProp({required this.prop, required this.leadSize});

  final SceneProp prop;
  final double leadSize;

  @override
  Widget build(BuildContext context) {
    final asset = prop.asset;
    if (asset == null) {
      return GardenLeaf(
        key: prop.key == null ? null : Key(prop.key!),
        size: prop.size!,
        angle: prop.angle,
        mirror: prop.mirror,
      );
    }
    return PixelDecoration(asset: asset, size: prop.size ?? leadSize);
  }
}
