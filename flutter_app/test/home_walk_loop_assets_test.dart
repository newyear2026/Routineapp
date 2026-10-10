import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/home/home_character_motion.dart';
import 'package:routine_timer/widgets/home/otter_home_motion.dart';
import 'package:routine_timer/widgets/home/penguin_home_motion.dart';
import 'package:routine_timer/widgets/home/poodle_home_motion.dart';
import 'package:routine_timer/widgets/home/rabbit_home_motion.dart';
import 'package:routine_timer/widgets/home/redpanda_home_motion.dart';
import 'package:routine_timer/widgets/home/sheep_home_motion.dart';
import 'package:routine_timer/widgets/home/squirrel_home_motion.dart';
import 'package:routine_timer/widgets/home/stargazer_home_motion.dart';
import 'package:routine_timer/widgets/home/starlight_home_motion.dart';

Future<Uint8List> atlasPixels(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  expect(frame.image.width, 1536);
  expect(frame.image.height, 768);
  final pixels =
      await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
  frame.image.dispose();
  codec.dispose();
  return pixels!.buffer.asUint8List();
}

int cellHash(Uint8List pixels, int frame) {
  var hash = 2166136261;
  final left = (frame % 4) * 384;
  final top = (frame ~/ 4) * 384;
  for (var y = top; y < top + 384; y++) {
    final start = (y * 1536 + left) * 4;
    for (var byte = start; byte < start + 384 * 4; byte++) {
      hash = ((hash ^ pixels[byte]) * 16777619) & 0xffffffff;
    }
  }
  return hash;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const packs = {
    'stargazer': StargazerHomeMotion.assets,
    'starlight': StarlightHomeMotion.assets,
    'poodle': PoodleHomeMotion.assets,
    'rabbit': RabbitHomeMotion.assets,
    'squirrel': SquirrelHomeMotion.assets,
    'sheep': SheepHomeMotion.assets,
    'redpanda': RedPandaHomeMotion.assets,
    'otter': OtterHomeMotion.assets,
    'penguin': PenguinHomeMotion.assets,
  };
  for (final entry in packs.entries) {
    test('${entry.key} bundles a distinct gait without copied idle endpoints',
        () async {
      final walkAsset = entry.value[HomeCharacterMotionClip.walk]!;
      expect(walkAsset, endsWith('/walk_loop_8.png'));
      final walk = await atlasPixels(walkAsset);
      final idle =
          await atlasPixels(entry.value[HomeCharacterMotionClip.idle]!);
      final neutral = cellHash(idle, 0);
      final gait = {
        for (var frame = 0; frame < 8; frame++) cellHash(walk, frame)
      };
      expect(gait, hasLength(8));
      // The old exporter copied the sitting neutral into frames 1 and 8.
      expect(gait, isNot(contains(neutral)));
    });
  }
  test('walking has equal frame exposure with no terminal hold', () {
    expect(HomeCharacterMotion.walkDurations, hasLength(8));
    expect(HomeCharacterMotion.walkDurations.toSet(),
        {const Duration(milliseconds: 120)});
  });
}
