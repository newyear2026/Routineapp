import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/home/home_cat_pose.dart';
export '../../application/home/home_cat_pose.dart';

/// Immutable source bounds, measured in the 1254px PNG coordinate system.
const _bounds = <CatPose, Rect>{
  CatPose.idle: Rect.fromLTRB(286, 213, 1054, 1083),
  CatPose.activity: Rect.fromLTRB(148, 248, 1120, 1072),
  CatPose.focus: Rect.fromLTRB(175, 186, 962, 1113),
  CatPose.complete: Rect.fromLTRB(73, 190, 1181, 1110),
  CatPose.rest: Rect.fromLTRB(219, 438, 1058, 969),
  CatPose.guide: Rect.fromLTRB(193, 158, 1034, 1105),
};

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
  const AnimatedCat({super.key, required this.pose, this.animate = true});
  final CatPose pose;
  final bool animate;
  static String asset(CatPose pose) =>
      'assets/characters/cat_starlight/v1/approved/${pose.name}.png';

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
  Widget build(BuildContext context) => IgnorePointer(
        child: ExcludeSemantics(child: RepaintBoundary(
          child: LayoutBuilder(builder: (context, constraints) {
            final bounds = _bounds[widget.pose]!;
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
                  width: 1254 * scale,
                  height: 1254 * scale,
                  child: Image.asset(
                    AnimatedCat.asset(widget.pose),
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
