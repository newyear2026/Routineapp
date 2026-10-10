import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/pack_skin.dart';

/// Only the scenery is graded. Text, characters and page surfaces keep their
/// original colors. Indoor scenes retain warmer lamplight at night.
ColorFilter? sceneLighting(PackSceneStyle style, PackScenePhase phase,
    {bool card = false}) {
  final (r, g, b, ro, go, bo) = switch (phase) {
    PackScenePhase.morning => (0.94, 0.86, 0.82, 20.0, 18.0, 22.0),
    PackScenePhase.day => (1.0, 1.0, 1.0, 0.0, 0.0, 0.0),
    PackScenePhase.sunset => (0.90, 0.60, 0.65, 33.0, 12.0, 18.0),
    // Cards stay moonlit and readable; the header alone carries the deep sky.
    PackScenePhase.night when style == PackSceneStyle.teashop && card => (
        0.78,
        0.67,
        0.56,
        8.0,
        9.0,
        17.0
      ),
    PackScenePhase.night when style == PackSceneStyle.teashop => (
        0.48,
        0.40,
        0.38,
        0.0,
        2.0,
        14.0
      ),
    PackScenePhase.night when card => (0.68, 0.72, 0.88, -22.0, -12.0, 5.0),
    PackScenePhase.night => (0.50, 0.60, 0.94, -45.0, -38.0, -10.0),
  };
  if (phase == PackScenePhase.day) return null;
  return ColorFilter.matrix([
    r,
    0,
    0,
    0,
    ro,
    0,
    g,
    0,
    0,
    go,
    0,
    0,
    b,
    0,
    bo,
    0,
    0,
    0,
    1,
    0,
  ]);
}

class ScenicPackBackdrop extends StatelessWidget {
  const ScenicPackBackdrop({
    super.key,
    required this.spec,
    required this.phase,
    this.subtle = false,
    this.animate = true,
  });

  final PackTimedScene spec;
  final PackScenePhase phase;
  final bool subtle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      spec.headers[phase.index],
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      filterQuality: FilterQuality.none,
      excludeFromSemantics: true,
    );
    final lighting = sceneLighting(spec.style, phase);
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: IgnorePointer(
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Colors.white, Colors.transparent],
              stops: [0, 0.54, 1],
            ).createShader(bounds),
            child: Stack(fit: StackFit.expand, children: [
              RepaintBoundary(
                child: lighting == null
                    ? image
                    : ColorFiltered(colorFilter: lighting, child: image),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: phase == PackScenePhase.night
                        ? const [Color(0x66152339), Color(0x00152339)]
                        : const [Color(0xB3FFF9EF), Color(0x00FFF9EF)],
                    stops: const [0, 0.72],
                  ),
                ),
              ),
              // Static sun/moon remains visible in Settings and reduced motion.
              if (spec.style != PackSceneStyle.teashop)
                CustomPaint(painter: _SkyLightPainter(phase)),
              if (animate)
                ScenicPackAtmosphere(
                  style: spec.style,
                  phase: phase,
                  subtle: subtle,
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SkyLightPainter extends CustomPainter {
  const _SkyLightPainter(this.phase);
  final PackScenePhase phase;

  @override
  void paint(Canvas canvas, Size size) {
    final moon = phase == PackScenePhase.night;
    final paint = Paint()
      ..color = phase == PackScenePhase.sunset
          ? const Color(0xFFFFDB9E)
          : const Color(0xFFFFF2BF);
    final cx = size.width * 0.87;
    final cy = phase == PackScenePhase.sunset ? 59.0 : 42.0;
    // Pixel silhouette; no solid patch covering the underlying sky.
    for (var y = -7; y <= 7; y++) {
      for (var x = -7; x <= 7; x++) {
        if (x * x + y * y > 49) continue;
        if (moon && (x - 3) * (x - 3) + (y + 2) * (y + 2) < 45) continue;
        canvas.drawRect(Rect.fromLTWH(cx + x * 2, cy + y * 2, 2, 2), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_SkyLightPainter oldDelegate) =>
      oldDelegate.phase != phase;
}

/// A single lifecycle for the five scenic families. Only this small paint layer
/// ticks; the raster scenery and layout are fixed.
class ScenicPackAtmosphere extends StatefulWidget {
  const ScenicPackAtmosphere({
    super.key,
    required this.style,
    required this.phase,
    this.subtle = false,
    this.card = false,
  });
  final PackSceneStyle style;
  final PackScenePhase phase;
  final bool subtle;
  final bool card;

  @override
  State<ScenicPackAtmosphere> createState() => _ScenicPackAtmosphereState();
}

class _ScenicPackAtmosphereState extends State<ScenicPackAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _foreground = state == null || state == AppLifecycleState.resumed;
    _motion = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.subtle ? 12 : 6),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(ScenicPackAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.subtle != oldWidget.subtle) {
      _motion.duration = Duration(seconds: widget.subtle ? 12 : 6);
      if (_motion.isAnimating) _motion.repeat();
    }
  }

  void _sync() {
    final enabled = _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_motion.isAnimating) _motion.repeat();
    if (!enabled && _motion.isAnimating) _motion.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _sync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _ScenicParticles(
            style: widget.style,
            phase: widget.phase,
            subtle: widget.subtle,
            card: widget.card,
            motion: _motion,
          ),
        ),
      ),
    );
  }
}

class _ScenicParticles extends CustomPainter {
  _ScenicParticles({
    required this.style,
    required this.phase,
    required this.subtle,
    required this.card,
    required this.motion,
  }) : super(repaint: motion);

  final PackSceneStyle style;
  final PackScenePhase phase;
  final bool subtle;
  final bool card;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = subtle ? 3 : 7;
    final t = motion.value;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var i = 0; i < count; i++) {
      final seed = i / count;
      final cycle = (t + seed) % 1;
      final pulse = math.pow(math.sin(cycle * math.pi), 2).toDouble();
      final drift = math.sin((t + seed) * math.pi * 2) * 5;
      final x = size.width * (0.62 + 0.30 * ((i * 0.618) % 1));
      final y = size.height * (card ? 0.2 + 0.32 * seed : 0.12 + 0.5 * seed);
      final paint = Paint()
        ..color = (phase == PackScenePhase.night
                ? const Color(0xFFFFECBB)
                : phase == PackScenePhase.sunset
                    ? const Color(0xFFFFE1B6)
                    : const Color(0xFFFFFCDF))
            .withValues(alpha: pulse * (subtle ? 0.32 : 0.65));
      switch (style) {
        case PackSceneStyle.stargazer:
          _star(canvas, x, y, paint);
          if (i == 0 && phase == PackScenePhase.night && !subtle) {
            for (var p = 0; p < 5; p++) {
              canvas.drawRect(
                  Rect.fromLTWH(
                      x - cycle * 35 + p * 3, y + cycle * 18 - p * 2, 3, 2),
                  paint);
            }
          }
        case PackSceneStyle.postal:
          if (phase == PackScenePhase.night) {
            _star(canvas, x + drift, y - cycle * 10, paint);
          } else {
            // Floating petals; a single butterfly in daylight.
            canvas.drawRect(
                Rect.fromLTWH(x + drift, y + cycle * 14, 4, 2), paint);
            if (i == 1 && phase == PackScenePhase.day) {
              canvas.drawRect(
                  Rect.fromLTWH(x + drift - 3, y + cycle * 14 - 2, 3, 4),
                  paint);
              canvas.drawRect(
                  Rect.fromLTWH(x + drift + 4, y + cycle * 14 - 2, 3, 4),
                  paint);
            }
          }
        case PackSceneStyle.cloud:
          if (phase == PackScenePhase.night) {
            _star(canvas, x, y, paint);
          } else {
            canvas.drawRect(Rect.fromLTWH(x + drift, y, 13, 2), paint);
            canvas.drawRect(Rect.fromLTWH(x + drift + 3, y - 2, 7, 2), paint);
          }
        case PackSceneStyle.teashop:
          // Steam in the card, rain limited to the right window in the header.
          if (card) {
            canvas.drawRect(
                Rect.fromLTWH(x + drift, y - cycle * 12, 2, 5), paint);
          } else {
            paint.color =
                const Color(0xFFDEE9ED).withValues(alpha: pulse * 0.4);
            canvas.drawRect(
                Rect.fromLTWH(size.width * 0.82 + i * 5, y + cycle * 22, 1, 5),
                paint);
          }
        case PackSceneStyle.seaside:
          // Horizontal water glints; no large moving surface behind text.
          canvas.drawRect(
              Rect.fromLTWH(
                  x + drift, size.height * 0.57 + i * 4, 5 + pulse * 8, 1.5),
              paint);
          if (i == 0 && phase == PackScenePhase.night) {
            _star(canvas, x, y, paint);
          }
        case PackSceneStyle.snowwalk:
          // Small drifting snow crystals stay in the scenery's right half.
          paint.color = (phase == PackScenePhase.night
                  ? const Color(0xFFDDE6FF)
                  : const Color(0xFFFFFFFF))
              .withValues(alpha: pulse * (subtle ? 0.42 : 0.76));
          _star(canvas, x + drift, y + cycle * 16, paint);
        case PackSceneStyle.squirrel:
        case PackSceneStyle.starlight:
        case PackSceneStyle.poodle:
          break; // These families retain their original dedicated painters.
      }
    }
    canvas.restore();
  }

  void _star(Canvas canvas, double x, double y, Paint paint) {
    canvas.drawRect(Rect.fromLTWH(x - 2, y, 6, 2), paint);
    canvas.drawRect(Rect.fromLTWH(x, y - 2, 2, 6), paint);
  }

  @override
  bool shouldRepaint(_ScenicParticles oldDelegate) =>
      style != oldDelegate.style ||
      phase != oldDelegate.phase ||
      subtle != oldDelegate.subtle ||
      card != oldDelegate.card;
}
