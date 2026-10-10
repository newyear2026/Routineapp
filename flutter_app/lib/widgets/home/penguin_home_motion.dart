import 'package:flutter/material.dart';

import '../../application/home/home_focus_state.dart';
import '../../data/store/character_pack_catalog.dart';
import '../ds/animated_cat.dart';
import 'home_character_motion.dart';

typedef PenguinMotionClip = HomeCharacterMotionClip;

/// Eight-frame home motions, triggered by changes to a routine occurrence.
class PenguinHomeMotion extends StatelessWidget {
  const PenguinHomeMotion({
    super.key,
    this.focusState = HomeFocusState.upcoming,
    this.routineKey,
    this.fallbackPose = CatPose.idle,
  });

  final HomeFocusState focusState;
  final String? routineKey;
  final CatPose fallbackPose;

  static const asset =
      'assets/characters/penguin_snow_walk/v1/motion/idle_8.png';
  static const assets = <PenguinMotionClip, String>{
    PenguinMotionClip.idle: asset,
    PenguinMotionClip.walk:
        'assets/characters/penguin_snow_walk/v1/motion/walk_loop_8.png',
    PenguinMotionClip.complete:
        'assets/characters/penguin_snow_walk/v1/motion/complete_8.png',
  };
  static const frameDurations = HomeCharacterMotion.frameDurations;
  static const walkDurations = HomeCharacterMotion.walkDurations;
  static const completeDurations = HomeCharacterMotion.completeDurations;
  static List<Duration> durationsFor(PenguinMotionClip clip) =>
      HomeCharacterMotion.durationsFor(clip);

  @override
  Widget build(BuildContext context) => HomeCharacterMotion(
        key: ValueKey(CharacterPackCatalog.penguinSnowWalk.id),
        focusState: focusState,
        routineKey: routineKey,
        fallbackPose: fallbackPose,
        pack: CharacterPackCatalog.penguinSnowWalk,
        assets: assets,
        label: 'penguin',
      );
}
