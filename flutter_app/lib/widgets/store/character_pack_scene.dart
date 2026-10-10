import 'package:flutter/material.dart';

import '../../domain/store/character_pack.dart';
import '../../theme/pack_skin_catalog.dart';
import 'character_pack_preview.dart';

/// The actual pack artwork, shared by collection tiles and the current-pack hero.
/// A stable scene keeps a shop visit independent of the device's time of day.
class CharacterPackScene extends StatelessWidget {
  const CharacterPackScene({
    super.key,
    required this.pack,
    required this.height,
    this.hero = false,
    this.child,
  });

  final CharacterPack pack;
  final double height;
  final bool hero;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final skin = PackSkinCatalog.of(pack);
    final scene = skin.timedScene;
    final asset = scene?.cardAt(hero ? 22 : 14) ?? skin.homeScene.backdrop;
    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: skin.widget.background.first),
          if (asset != null)
            Image.asset(asset,
                fit: BoxFit.cover,
                alignment: hero ? Alignment.centerRight : Alignment.center,
                filterQuality: FilterQuality.low,
                excludeFromSemantics: true),
          if (hero)
            // A solid translucent veil keeps text legible on every pack's art.
            const ColoredBox(color: Color(0xAA221C42)),
          Align(
            alignment: hero ? Alignment.bottomRight : Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(right: hero ? 8 : 0, bottom: 4),
              child: ExcludeSemantics(
                child: CharacterPackPortrait(
                    pack: pack,
                    size: hero ? (height * .85).clamp(100, 160) : height * .90),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
