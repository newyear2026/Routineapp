import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../ds/animated_cat.dart';

/// 별빛 고양이 홈 카드의 세 가지 상태. 루틴 이름이나 아이콘은 보지 않는다.
enum StarlightHomeMode { idle, active, complete }

/// 승인된 포즈와 걷기 시안 프레임을 번갈아 보여 주는 홈 전용 프로토타입.
class StarlightHomeMotion extends StatefulWidget {
  const StarlightHomeMotion({super.key, required this.mode});

  final StarlightHomeMode mode;

  @override
  State<StarlightHomeMotion> createState() => _StarlightHomeMotionState();
}

typedef _Frame = ({double dx, double dy, double sx, double sy});

const _neutral = (dx: 0.0, dy: 0.0, sx: 1.0, sy: 1.0);
const _idleFrames = <_Frame>[
  _neutral,
  (dx: 0, dy: -1, sx: .99, sy: 1.02),
  (dx: 0, dy: -1, sx: .99, sy: 1.02),
  _neutral,
];
const _activeFrames = <_Frame>[
  _neutral,
  (dx: 1, dy: -1, sx: 1, sy: 1),
  (dx: 1, dy: 0, sx: 1, sy: 1),
  (dx: 2, dy: -1, sx: 1, sy: 1),
  _neutral,
];
const _completeFrames = <_Frame>[
  _neutral,
  (dx: 0, dy: 0, sx: 1.03, sy: .96),
  (dx: 0, dy: -3, sx: .99, sy: 1.02),
  (dx: 0, dy: -5, sx: 1, sy: 1),
  (dx: 0, dy: -2, sx: .99, sy: 1.01),
  _neutral,
];

class _StarlightHomeMotionState extends State<StarlightHomeMotion>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion = AnimationController(vsync: this);
  Timer? _pause;
  bool _foreground = true;
  bool _celebrating = false;
  bool _walkRequested = false;
  bool _walkReady = false;

  bool get _enabled =>
      _foreground &&
      !MediaQuery.disableAnimationsOf(context) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _motion.addStatusListener((status) {
      if (status == AnimationStatus.completed && _celebrating && mounted) {
        setState(() => _celebrating = false);
      }
    });
  }

  void _schedule({bool celebrate = false}) {
    _pause?.cancel();
    _motion.stop();
    _motion.value = 0;
    _celebrating = celebrate && _enabled;
    if (!_enabled) return;

    if (widget.mode == StarlightHomeMode.complete) {
      // 이미 완료된 상태로 홈에 들어오면 축하를 다시 재생하지 않는다.
      if (_celebrating) {
        _motion.duration = const Duration(milliseconds: 900);
        _motion.forward();
      }
      return;
    }

    final active = widget.mode == StarlightHomeMode.active;
    if (active) {
      _motion.duration = const Duration(milliseconds: 1000);
      _motion.forward();
      _pause = Timer.periodic(const Duration(milliseconds: 1500), (_) {
        if (mounted && _enabled) _motion.forward(from: 0);
      });
      return;
    }

    _motion.duration = const Duration(milliseconds: 1200);
    _motion.forward();
    _pause = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && _enabled) _motion.forward(from: 0);
    });
  }

  void _ensureWalkStepLoaded() {
    if (_walkRequested || widget.mode != StarlightHomeMode.active) return;
    _walkRequested = true;
    unawaited(Future.wait([
      precacheImage(
        const ResizeImage(AssetImage(_activityAsset), width: 384),
        context,
      ),
      precacheImage(
        const ResizeImage(AssetImage(_walkStepAsset), width: 384),
        context,
      ),
    ]).then((_) {
      if (!mounted) return;
      setState(() => _walkReady = true);
      if (widget.mode == StarlightHomeMode.active) _schedule();
    }));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureWalkStepLoaded();
    _schedule();
  }

  @override
  void didUpdateWidget(StarlightHomeMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _ensureWalkStepLoaded();
      _schedule(
        celebrate: oldWidget.mode == StarlightHomeMode.active &&
            widget.mode == StarlightHomeMode.complete,
      );
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
    return IgnorePointer(
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final frames = switch (widget.mode) {
              StarlightHomeMode.idle => _idleFrames,
              StarlightHomeMode.active => _activeFrames,
              StarlightHomeMode.complete => _completeFrames,
            };
            final frameIndex = (_motion.value * (frames.length - 1)).floor();
            final frame =
                widget.mode == StarlightHomeMode.complete && !_celebrating
                    ? _neutral
                    : frames[frameIndex];
            final alternateStep = _walkReady &&
                widget.mode == StarlightHomeMode.active &&
                (frameIndex == 1 || frameIndex == 3);
            final pose = switch (widget.mode) {
              StarlightHomeMode.idle => CatPose.idle,
              StarlightHomeMode.active => CatPose.activity,
              StarlightHomeMode.complete => _celebrating && _motion.value < .2
                  ? CatPose.idle
                  : CatPose.complete,
            };

            return Stack(
              fit: StackFit.expand,
              children: [
                Transform.translate(
                  offset: Offset(frame.dx, frame.dy),
                  child: Transform.scale(
                    alignment: Alignment.bottomCenter,
                    scaleX: frame.sx,
                    scaleY: frame.sy,
                    child: widget.mode == StarlightHomeMode.active && _walkReady
                        ? _StarlightActiveStep(alternate: alternateStep)
                        : AnimatedCat(pose: pose, animate: false),
                  ),
                ),
                if (_celebrating)
                  CustomPaint(
                    painter: _StarlightSparkles(_motion.value),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

const _walkStepAsset =
    'assets/characters/cat_starlight/v1/prototype/walk_step.png';
const _activityAsset =
    'assets/characters/cat_starlight/v1/approved/activity.png';

/// 두 발 프레임을 하나의 Image에서 전환해 빈 프레임 없이 바닥선을 맞춘다.
class _StarlightActiveStep extends StatelessWidget {
  const _StarlightActiveStep({required this.alternate});

  final bool alternate;

  static const _canvas = 1254.0;
  static const _activityBounds = Rect.fromLTRB(148, 248, 1120, 1072);
  static const _walkBounds = Rect.fromLTRB(49, 53, 1210, 1254);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final bounds = alternate ? _walkBounds : _activityBounds;
      final scale = math.min(
            constraints.maxWidth / bounds.width,
            constraints.maxHeight / bounds.height,
          ) *
          .94;
      return ClipRect(
        child: Stack(children: [
          Positioned(
            left: (constraints.maxWidth - bounds.width * scale) / 2 -
                bounds.left * scale,
            top: constraints.maxHeight - bounds.bottom * scale,
            width: _canvas * scale,
            height: _canvas * scale,
            child: Image.asset(
              alternate ? _walkStepAsset : _activityAsset,
              key: const Key('starlight-active-image'),
              filterQuality: FilterQuality.none,
              cacheWidth: 384,
              gaplessPlayback: true,
              excludeFromSemantics: true,
            ),
          ),
        ]),
      );
    });
  }
}

/// 카드 오른쪽 88×96 영역 안에서만 보이는 작은 픽셀 별.
class _StarlightSparkles extends CustomPainter {
  const _StarlightSparkles(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress < .2 || progress >= .9) return;
    final fade = progress < .4
        ? (progress - .2) / .2
        : progress > .7
            ? (.9 - progress) / .2
            : 1.0;
    final paint = Paint()
      ..color = const Color(0xFFFFD46B).withValues(alpha: fade);
    final pixel = size.width / 88 * 2;
    for (final point in const [
      Offset(.12, .38),
      Offset(.25, .13),
      Offset(.78, .12),
      Offset(.9, .42),
    ]) {
      final x = point.dx * size.width;
      final y = point.dy * size.height;
      canvas.drawRect(
        Rect.fromLTWH(x - pixel / 2, y - pixel * 1.5, pixel, pixel * 3),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - pixel * 1.5, y - pixel / 2, pixel * 3, pixel),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StarlightSparkles oldDelegate) =>
      oldDelegate.progress != progress;
}
