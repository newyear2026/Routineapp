import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../application/home/home_focus_state.dart';
import '../../domain/store/character_pack.dart';
import '../ds/animated_cat.dart';

enum HomeCharacterMotionClip { idle, walk, complete }

/// Eight drawings per clip. Idle and active walking loop while visible;
/// completion plays once when the routine changes state, then holds.
class HomeCharacterMotion extends StatefulWidget {
  const HomeCharacterMotion({
    super.key,
    this.focusState = HomeFocusState.upcoming,
    this.routineKey,
    this.fallbackPose = CatPose.idle,
    required this.pack,
    required this.assets,
    required this.label,
    this.flipWalkHorizontally = false,
    this.spriteBounds = const Rect.fromLTRB(16, 0, 370, 364),
  });

  final HomeFocusState focusState;

  /// Date + routine ID distinguish adjacent routines and daily occurrences.
  final String? routineKey;
  final CatPose fallbackPose;

  final CharacterPack pack;
  final Map<HomeCharacterMotionClip, String> assets;
  final String label;

  /// Mirror walking cells without changing idle or completion poses.
  final bool flipWalkHorizontally;
  final Rect spriteBounds;

  static const frameDurations = <Duration>[
    Duration(milliseconds: 2800),
    Duration(milliseconds: 180),
    Duration(milliseconds: 100),
    Duration(milliseconds: 120),
    Duration(milliseconds: 100),
    Duration(milliseconds: 100),
    Duration(milliseconds: 180),
    Duration(milliseconds: 420),
  ];
  // Equal exposure for every gait phase; no terminal neutral hold.
  static const walkDurations = <Duration>[
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
    Duration(milliseconds: 120),
  ];
  static const completeDurations = <Duration>[
    Duration(milliseconds: 100),
    Duration(milliseconds: 120),
    Duration(milliseconds: 140),
    Duration(milliseconds: 180),
    Duration(milliseconds: 140),
    Duration(milliseconds: 140),
    Duration(milliseconds: 160),
    Duration(milliseconds: 220),
  ];

  static List<Duration> durationsFor(HomeCharacterMotionClip clip) =>
      switch (clip) {
        HomeCharacterMotionClip.idle => frameDurations,
        HomeCharacterMotionClip.walk => walkDurations,
        HomeCharacterMotionClip.complete => completeDurations,
      };

  @override
  State<HomeCharacterMotion> createState() => _HomeCharacterMotionState();
}

class _HomeCharacterMotionState extends State<HomeCharacterMotion>
    with WidgetsBindingObserver {
  Timer? _timer;
  HomeCharacterMotionClip _clip = HomeCharacterMotionClip.idle;
  int _frame = 0;
  final _ready = <HomeCharacterMotionClip>{};
  final _failed = <HomeCharacterMotionClip>{};
  bool _loading = false;
  bool _motionAllowed = false;
  late bool _foreground;

  bool get _enabled => _foreground && _motionAllowed;
  bool get _completed =>
      widget.focusState == HomeFocusState.completed ||
      widget.focusState == HomeFocusState.dayDone;
  bool get _usesAtlas =>
      _completed ||
      widget.focusState == HomeFocusState.active ||
      widget.fallbackPose == CatPose.idle;

  @override
  void initState() {
    super.initState();
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _settle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final allowed = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (_motionAllowed != allowed) {
      _motionAllowed = allowed;
      _settle();
      _scheduleNextFrame();
    }
    if (!_loading) {
      _loading = true;
      for (final clip in HomeCharacterMotionClip.values) {
        unawaited(_loadAtlas(clip));
      }
    }
  }

  @override
  void didUpdateWidget(HomeCharacterMotion oldWidget) {
    super.didUpdateWidget(oldWidget);
    final routineChanged = widget.routineKey != oldWidget.routineKey;
    if (!routineChanged &&
        widget.focusState == oldWidget.focusState &&
        widget.fallbackPose == oldWidget.fallbackPose) {
      return;
    }

    final completes = !routineChanged &&
        widget.focusState == HomeFocusState.completed &&
        (oldWidget.focusState == HomeFocusState.active ||
            oldWidget.focusState == HomeFocusState.snoozed);
    if (_enabled && completes) {
      _timer?.cancel();
      _clip = HomeCharacterMotionClip.complete;
      _frame = 0;
      if (_failed.contains(_clip)) _settle();
    } else {
      _settle();
    }
    _scheduleNextFrame();
  }

  Future<void> _loadAtlas(HomeCharacterMotionClip clip) async {
    var failed = false;
    await precacheImage(AssetImage(widget.assets[clip]!), context,
        onError: (error, stack) => failed = true);
    if (!mounted) return;
    setState(() {
      if (failed) {
        _failed.add(clip);
        if (_clip == clip) _settle();
      } else {
        _ready.add(clip);
      }
    });
    if (_clip == clip) _scheduleNextFrame();
  }

  void _settle() {
    _timer?.cancel();
    _clip = _completed
        ? HomeCharacterMotionClip.complete
        : _enabled &&
                widget.focusState == HomeFocusState.active &&
                !_failed.contains(HomeCharacterMotionClip.walk)
            ? HomeCharacterMotionClip.walk
            : HomeCharacterMotionClip.idle;
    _frame = _completed ? 7 : 0;
  }

  void _scheduleNextFrame() {
    _timer?.cancel();
    if (!_enabled ||
        !_usesAtlas ||
        !_ready.contains(_clip) ||
        (_clip == HomeCharacterMotionClip.complete && _frame == 7)) {
      return;
    }
    _timer = Timer(HomeCharacterMotion.durationsFor(_clip)[_frame], () {
      if (!mounted || !_enabled) return;
      setState(() {
        if (_frame == 7) {
          // Keep the current loop until the routine or visibility changes.
          _frame = 0;
        } else {
          _frame++;
        }
      });
      _scheduleNextFrame();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    _foreground = state == AppLifecycleState.resumed;
    setState(_settle);
    _scheduleNextFrame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesAtlas || !_ready.contains(_clip)) {
      return AnimatedCat(
        pose: _completed ? CatPose.complete : widget.fallbackPose,
        animate: !_usesAtlas,
        homeMotion: true,
        pack: widget.pack,
      );
    }
    return IgnorePointer(
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ClipRect(
            child: LayoutBuilder(builder: (context, constraints) {
              // Shared stage includes the extended walking tail and hop's
              // headroom. Never auto-fit individual frames: feet would slide.
              final bounds = widget.spriteBounds;
              final scale = math.min(
                    constraints.maxWidth / bounds.width,
                    constraints.maxHeight / bounds.height,
                  ) *
                  .94;
              return Stack(children: [
                Positioned(
                  left: (constraints.maxWidth - bounds.width * scale) / 2 -
                      bounds.left * scale,
                  top: constraints.maxHeight - bounds.bottom * scale,
                  width: 384 * scale,
                  height: 384 * scale,
                  // Clip the cell as well as the outer slot: otherwise a
                  // previous row's paws can peek into unused headroom.
                  child: Transform.flip(
                    flipX: widget.flipWalkHorizontally &&
                        _clip == HomeCharacterMotionClip.walk,
                    // Mirror the selected cell, not the atlas or frame order.
                    child: ClipRect(
                      child: Stack(children: [
                        Positioned(
                          key: ValueKey('${widget.label}-atlas-position'),
                          left: -(_frame % 4) * 384 * scale,
                          top: -(_frame ~/ 4) * 384 * scale,
                          width: 1536 * scale,
                          height: 768 * scale,
                          child: Image.asset(
                            widget.assets[_clip]!,
                            key:
                                ValueKey('${widget.label}-${_clip.name}-image'),
                            filterQuality: FilterQuality.none,
                            gaplessPlayback: true,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ]),
                    ),
                  ),
                ),
              ]);
            }),
          ),
        ),
      ),
    );
  }
}
