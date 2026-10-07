import 'package:flutter/material.dart';

import '../../application/home/home_focus_state.dart';
import '../../data/store/character_pack_catalog.dart';
import '../ds/animated_cat.dart';
import 'home_character_motion.dart';

typedef SheepMotionClip = HomeCharacterMotionClip;

/// Eight-frame home motions, triggered by changes to a routine occurrence.
class SheepHomeMotion extends StatelessWidget {
  const SheepHomeMotion({
    super.key,
    this.focusState = HomeFocusState.upcoming,
    this.routineKey,
    this.fallbackPose = CatPose.idle,
  });

  final HomeFocusState focusState;
  final String? routineKey;
  final CatPose fallbackPose;

  static const asset = 'assets/characters/sheep_mooncloud/v1/motion/idle_8.png';
  static const assets = <SheepMotionClip, String>{
    SheepMotionClip.idle: asset,
    SheepMotionClip.walk:
        'assets/characters/sheep_mooncloud/v1/motion/walk_loop_8.png',
    SheepMotionClip.complete:
        'assets/characters/sheep_mooncloud/v1/motion/complete_8.png',
  };
  static const frameDurations = HomeCharacterMotion.frameDurations;
  static const walkDurations = HomeCharacterMotion.walkDurations;
  static const completeDurations = HomeCharacterMotion.completeDurations;
  static List<Duration> durationsFor(SheepMotionClip clip) =>
      HomeCharacterMotion.durationsFor(clip);

  @override
  Widget build(BuildContext context) => HomeCharacterMotion(
        key: ValueKey(CharacterPackCatalog.mooncloudSheep.id),
        focusState: focusState,
        routineKey: routineKey,
        fallbackPose: fallbackPose,
        pack: CharacterPackCatalog.mooncloudSheep,
        assets: assets,
        label: 'sheep',
      );
}
