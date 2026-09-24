import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/home/home_cat_pose.dart';
import '../../data/store/character_pack_catalog.dart';
import '../../domain/store/character_pack.dart';
import '../store/character_pack_scope.dart';
export '../../application/home/home_cat_pose.dart';

/// 캐릭터 그림의 캔버스 크기와 포즈별 실제 그림 영역.
///
/// 그림마다 여백이 달라 영역을 재어 둬야 바닥선에 맞춰 세울 수 있다.
/// 그림을 가진 팩을 새로 실으면 여기에 그 캐릭터의 값을 더한다 —
/// 빠뜨리면 character_pack_screen_test 가 먼저 멈춘다.
class CharacterArtwork {
  const CharacterArtwork({required this.canvas, required this.bounds});

  /// 정사각 원본 PNG의 한 변(px).
  final double canvas;

  /// 원본 좌표계에서 잰 포즈별 그림 영역.
  final Map<CatPose, Rect> bounds;

  static const byCharacter = <String, CharacterArtwork>{
    'cat_starlight': CharacterArtwork(
      canvas: 1254,
      bounds: {
        CatPose.idle: Rect.fromLTRB(286, 213, 1054, 1083),
        CatPose.activity: Rect.fromLTRB(148, 248, 1120, 1072),
        CatPose.focus: Rect.fromLTRB(175, 186, 962, 1113),
        CatPose.complete: Rect.fromLTRB(73, 190, 1181, 1110),
        CatPose.rest: Rect.fromLTRB(219, 438, 1058, 969),
        CatPose.guide: Rect.fromLTRB(193, 158, 1034, 1105),
      },
    ),
    'poodle_garden': CharacterArtwork(
      canvas: 384,
      bounds: {
        CatPose.idle: Rect.fromLTRB(82, 55, 320, 337),
        CatPose.activity: Rect.fromLTRB(46, 68, 337, 332),
        CatPose.focus: Rect.fromLTRB(75, 69, 309, 340),
        CatPose.complete: Rect.fromLTRB(71, 16, 344, 320),
        CatPose.rest: Rect.fromLTRB(35, 127, 351, 301),
        CatPose.guide: Rect.fromLTRB(47, 38, 350, 354),
      },
    ),
  };
}

/// Each sequence starts and ends at neutral. Scaling uses the grounded anchor.
const _frames = <CatPose, List<double>>{
  CatPose.idle: [0, .15, .4, .6, .4, .15, 0],
  CatPose.activity: [0, .8, 0, 1, 0, .8, 0],
  CatPose.focus: [0, -.4, -.8, -.4, 0],
  CatPose.complete: [0, -.6, 1, .5, -.3, 0],
  CatPose.rest: [0, .2, .5, 1, .5, .2, 0],
  CatPose.guide: [0, .5, -.3, .5, 0],
};

class AnimatedCat extends StatefulWidget {
  const AnimatedCat({
    super.key,
    required this.pose,
    this.animate = true,
    this.pack,
  });
  final CatPose pose;
  final bool animate;

  /// 그릴 팩. null이면 [CharacterPackScope]의 지금 쓰는 팩을 그린다 —
  /// 팩 목록처럼 특정 팩을 보여 줘야 하는 자리만 넘긴다.
  final CharacterPack? pack;

  /// 실제로 그릴 팩. 그림이 없거나 영역을 재지 않은 팩은 기본 팩으로 내린다.
  ///
  /// 빈 자리를 그리느니 기본 캐릭터를 그린다. 이 길은 판정
  /// (`CharacterPackCatalog.resolve`)이 이미 막아 둔 경우라 정상 흐름에서는
  /// 타지 않는다.
  static CharacterPack drawablePack(CharacterPack pack) {
    final characterId = pack.characterId;
    if (characterId == null ||
        !CharacterArtwork.byCharacter.containsKey(characterId)) {
      return CharacterPackCatalog.defaultPack;
    }
    return pack;
  }

  @override
  State<AnimatedCat> createState() => _AnimatedCatState();
}

class _AnimatedCatState extends State<AnimatedCat>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800));
  Timer? _pause;
  bool _foreground = true;
  bool get _enabled =>
      widget.animate &&
      _foreground &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _schedule() {
    _pause?.cancel();
    _motion.stop();
    _motion.value = 0;
    if (!_enabled) return;
    // Long rests keep the surrounding routine controls visually quiet.
    _pause = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && _enabled) _motion.forward(from: 0);
    });
    _motion.forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedule();
  }

  @override
  void didUpdateWidget(AnimatedCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose != widget.pose || oldWidget.animate != widget.animate) {
      _schedule();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _schedule();
  }

  @override
  void dispose() {
    _pause?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pack = AnimatedCat.drawablePack(
        widget.pack ?? CharacterPackScope.currentOf(context));
    final artwork = CharacterArtwork.byCharacter[pack.characterId]!;
    return IgnorePointer(
      child: ExcludeSemantics(child: RepaintBoundary(
        child: LayoutBuilder(builder: (context, constraints) {
          final bounds = artwork.bounds[widget.pose]!;
          final scale = math.min(constraints.maxWidth / bounds.width,
                  constraints.maxHeight / bounds.height) *
              .94;
          return ClipRect(
              child: AnimatedBuilder(
            animation: _motion,
            builder: (context, child) {
              final frames = _frames[widget.pose]!;
              final index = (_motion.value * (frames.length - 1)).floor();
              final amount = frames[index];
              return Transform(
                alignment: Alignment.bottomCenter,
                transform: Matrix4.diagonal3Values(
                    1 - amount * .008, 1 + amount * .025, 1),
                child: child,
              );
            },
            child: Stack(children: [
              Positioned(
                left: (constraints.maxWidth - bounds.width * scale) / 2 -
                    bounds.left * scale,
                top: constraints.maxHeight - bounds.bottom * scale,
                width: artwork.canvas * scale,
                height: artwork.canvas * scale,
                child: Image.asset(
                  pack.assetFor(widget.pose.name)!,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.none,
                  cacheWidth: 384,
                  excludeFromSemantics: true,
                ),
              ),
            ]),
          ));
        }),
      )),
    );
  }
}
