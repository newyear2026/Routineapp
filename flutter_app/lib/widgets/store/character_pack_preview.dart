import 'package:flutter/material.dart';

import '../../domain/store/character_pack.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../ds/animated_cat.dart';
import '../ds/pixel_decoration.dart';

/// 팩의 캐릭터 초상. 그림이 없는 팩은 빈 자리를 그대로 보여 준다.
///
/// 없는 그림을 다른 캐릭터로 대신 채우면, 사는 사람이 받을 것과 화면이
/// 보여 주는 것이 달라진다. 스토어 화면에서 이건 환불 사유다.
class CharacterPackPortrait extends StatelessWidget {
  const CharacterPackPortrait({
    super.key,
    required this.pack,
    this.size = 132,
    this.animate = false,
  });

  final CharacterPack pack;
  final double size;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    if (!pack.hasArtwork) {
      return _PendingArtwork(size: size);
    }
    // `AnimatedCat`은 아직 제 경로를 직접 만든다. 그림을 가진 팩이 하나뿐이라
    // 지금은 어긋나지 않으며, 둘째가 생기는 순간
    // character_pack_screen_test 가 먼저 깨져 캐릭터 축을 풀게 한다.
    return SizedBox(
      width: size,
      height: size,
      child: AnimatedCat(pose: CatPose.idle, animate: animate),
    );
  }
}

class _PendingArtwork extends StatelessWidget {
  const _PendingArtwork({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.characterPackArtworkPending,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: AppColors.orbitSurfaceSoft,
          shape: AppPixelStyle.shape(color: AppColors.orbitBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.brush_outlined,
                color: AppColors.textMuted, size: 28),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                l10n.characterPackArtworkPending,
                textAlign: TextAlign.center,
                style: AppTextStyles.captionTight
                    .copyWith(color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 팩이 제공하는 색 변형.
///
/// 색은 [AppThemePreset]에서 가져온다 — 이 프리셋이 **아직 화면을 칠하지
/// 않는다**는 점은 그대로다. 팩이 배경을 바꾸려면 `AppColors` 직접 참조를
/// 토큰 경유로 옮기는 일이 먼저 끝나야 한다.
class CharacterPackColorRow extends StatelessWidget {
  const CharacterPackColorRow({super.key, required this.pack});

  final CharacterPack pack;

  List<Color> get _colors {
    final seen = <int>{};
    final colors = <Color>[];
    for (final id in pack.paletteIds) {
      for (final color in AppThemePreset.byId(id).previewColors) {
        if (seen.add(color.toARGB32())) colors.add(color);
      }
    }
    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final color in _colors)
          Container(
            width: 30,
            height: 30,
            decoration: ShapeDecoration(
              color: color,
              shape: AppPixelStyle.shape(
                color: AppColors.orbitBorder,
                steps: 1,
              ),
            ),
          ),
      ],
    );
  }
}

/// 팩이 제공하는 장식.
class CharacterPackDecoRow extends StatelessWidget {
  const CharacterPackDecoRow({super.key, required this.pack});

  final CharacterPack pack;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final deco in pack.decoIds) PixelDecoration(asset: deco, size: 40),
      ],
    );
  }
}
