import 'package:flutter/material.dart';

import '../../domain/models/routine_icon_id.dart';

/// 시안의 다색 픽셀 아트를 루틴 선택·미리보기·목록에서 공통으로 사용한다.
///
/// [color]는 기존 호출부 및 저장 모델과의 호환을 위해 유지한다. 루틴 색은
/// 배지와 시간표에서 사용하고, 아이콘 그림은 시안처럼 고유한 색을 보존한다.
class RoutineMark extends StatelessWidget {
  const RoutineMark({
    super.key,
    required this.icon,
    required this.color,
    this.size = 36,
  });

  final RoutineIconId icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: Image.asset(
          'assets/routine_icons/${icon.name}.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none,
          excludeFromSemantics: true,
        ),
      );
}
