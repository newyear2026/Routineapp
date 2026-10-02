import 'package:flutter/material.dart';

import '../../theme/pack_skin.dart';
import '../store/character_pack_scope.dart';
import 'poodle_garden_backdrop.dart';
import 'scenic_pack_backdrop.dart';
import 'squirrel_forest_backdrop.dart';
import 'squirrel_time_of_day.dart';
import 'starlight_time_of_day.dart';

/// 화면에서 팩 ID를 검사하지 않고 팩의 시간대 장면을 읽는 진입점.
class PackTimeScene {
  const PackTimeScene._(this.spec, this.phase, this.hour);

  final PackTimedScene spec;
  final PackScenePhase phase;
  final int hour;

  static PackTimeScene? of(BuildContext context, int hour) {
    final spec = CharacterPackScope.skinOf(context).timedScene;
    if (spec == null) return null;
    return PackTimeScene._(spec, PackScenePhase.fromHour(hour), hour);
  }

  String get cardAsset => spec.cardAt(hour);
  bool get hasLightHeaderText => spec.lightHeaderAt(hour);
  Color? get bodyColor => hasLightHeaderText ? spec.nightBodyColor : null;
  bool get isPoodle => spec.style == PackSceneStyle.poodle;
  bool get usesTextVeil =>
      spec.graded ||
      spec.style == PackSceneStyle.poodle ||
      spec.style == PackSceneStyle.starlight;

  ColorFilter? get cardLighting =>
      spec.graded ? sceneLighting(spec.style, phase, card: true) : null;

  Widget backdrop({bool subtle = false, bool animate = true}) =>
      switch (spec.style) {
        PackSceneStyle.squirrel => SquirrelForestBackdrop(
            timeOfDay: SquirrelTimeOfDay.fromHour(hour),
            motion: !animate
                ? SquirrelForestMotion.none
                : subtle
                    ? SquirrelForestMotion.subtle
                    : SquirrelForestMotion.full,
          ),
        PackSceneStyle.starlight => StarlightSkyBackdrop(
            timeOfDay: StarlightTimeOfDay.fromHour(hour),
            subtle: subtle,
            animate: animate,
          ),
        PackSceneStyle.poodle => PoodleGardenBackdrop(
            phase: phase,
            headerAsset: spec.headerAt(hour),
            subtle: subtle,
            animate: animate,
          ),
        _ => ScenicPackBackdrop(
            spec: spec, phase: phase, subtle: subtle, animate: animate),
      };

  Widget? cardAtmosphere() => switch (spec.style) {
        PackSceneStyle.squirrel => SquirrelAtmosphere(
            timeOfDay: SquirrelTimeOfDay.fromHour(hour),
            area: SquirrelAtmosphereArea.card,
          ),
        PackSceneStyle.starlight => null,
        PackSceneStyle.poodle =>
          PoodleGardenAtmosphere(phase: phase, card: true),
        _ => ScenicPackAtmosphere(style: spec.style, phase: phase, card: true),
      };
}
