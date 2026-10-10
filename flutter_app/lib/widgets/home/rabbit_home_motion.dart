import 'package:flutter/material.dart';

import '../../application/home/home_focus_state.dart';
import '../../data/store/character_pack_catalog.dart';
import '../ds/animated_cat.dart';
import 'home_character_motion.dart';

typedef RabbitMotionClip = HomeCharacterMotionClip;

/// Eight-frame home motions, triggered by changes to a routine occurrence.
class RabbitHomeMotion extends StatelessWidget {
  const RabbitHomeMotion({
    super.key,
    this.focusState = HomeFocusState.upcoming,
    this.routineKey,
    this.fallbackPose = CatPose.idle,
  });

  final HomeFocusState focusState;
  final String? routineKey;
  final CatPose fallbackPose;

  static const asset = 'assets/characters/rabbit_postman/v1/motion/idle_8.png';
  static const assets = <RabbitMotionClip, String>{
    RabbitMotionClip.idle: asset,
    RabbitMotionClip.walk:
        'assets/characters/rabbit_postman/v1/motion/walk_loop_8.png',
    RabbitMotionClip.complete:
        'assets/characters/rabbit_postman/v1/motion/complete_8.png',
  };
  static const frameDurations = HomeCharacterMotion.frameDurations;
  static const walkDurations = HomeCharacterMotion.walkDurations;
  static const completeDurations = HomeCharacterMotion.completeDurations;
  static List<Duration> durationsFor(RabbitMotionClip clip) =>
      HomeCharacterMotion.durationsFor(clip);

  @override
  Widget build(BuildContext context) => HomeCharacterMotion(
        key: ValueKey(CharacterPackCatalog.postmanRabbit.id),
        focusState: focusState,
        routineKey: routineKey,
        fallbackPose: fallbackPose,
        pack: CharacterPackCatalog.postmanRabbit,
        assets: assets,
        label: 'rabbit',
      );
}
