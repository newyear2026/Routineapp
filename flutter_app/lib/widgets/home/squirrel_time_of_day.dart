import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/store/character_pack_catalog.dart';
import '../../theme/pack_skin.dart';
import '../../theme/pack_skin_catalog.dart';

/// 다람쥐 숲의 네 장면. 앱이 표시하는 [TimeOfDay]와 같은 기기 시각을 쓴다.
enum SquirrelTimeOfDay {
  morning,
  day,
  sunset,
  night;

  static SquirrelTimeOfDay fromHour(int hour) =>
      values[PackScenePhase.fromHour(hour).index];

  static PackTimedScene get _scene =>
      PackSkinCatalog.of(CharacterPackCatalog.explorerSquirrel).timedScene!;

  String get headerAsset => _scene.headers[index];

  String get cardAsset => _scene.cards[index];

  bool get hasLightHeaderText => this == night;
}

enum SquirrelAtmosphereArea { header, card }

/// 숲 이미지는 고정하고 작은 픽셀 파티클만 움직인다.
///
/// 홈이 배경에 가거나 시스템의 애니메이션 축소가
/// 켜지면 ticker를 멈춘다. CustomPaint만 다시 그려 이미지·글자는 다시 그리지
/// 않는다.
class SquirrelAtmosphere extends StatefulWidget {
  const SquirrelAtmosphere({
    super.key,
    required this.timeOfDay,
    required this.area,
    this.subtle = false,
  });

  final SquirrelTimeOfDay timeOfDay;
  final SquirrelAtmosphereArea area;
  final bool subtle;

  @override
  State<SquirrelAtmosphere> createState() => _SquirrelAtmosphereState();
}

class _SquirrelAtmosphereState extends State<SquirrelAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _motion;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.subtle ? 12 : 6),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(SquirrelAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtle != widget.subtle) {
      _motion.duration = Duration(seconds: widget.subtle ? 12 : 6);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _syncMotion();
  }

  void _syncMotion() {
    final enabled = _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_motion.isAnimating) {
      _motion.repeat();
    } else if (!enabled && _motion.isAnimating) {
      _motion.stop();
    }
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
          painter: _SquirrelParticlePainter(
            timeOfDay: widget.timeOfDay,
            area: widget.area,
            subtle: widget.subtle,
            motion: _motion,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _SquirrelParticlePainter extends CustomPainter {
  _SquirrelParticlePainter({
    required this.timeOfDay,
    required this.area,
    required this.subtle,
    required this.motion,
  }) : super(repaint: motion);

  final SquirrelTimeOfDay timeOfDay;
  final SquirrelAtmosphereArea area;
  final bool subtle;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = motion.value;
    final unit = (math.min(size.width / 390, size.height / 250) * 2.5)
        .round()
        .clamp(2, 4)
        .toDouble();

    if (area == SquirrelAtmosphereArea.card) {
      _paintCard(canvas, size, t, unit);
      return;
    }

    if (subtle) {
      _paintSubtleHeader(canvas, size, t, unit);
      return;
    }

    switch (timeOfDay) {
      case SquirrelTimeOfDay.morning:
        for (var i = 0; i < 4; i++) {
          final phase = (t + i * 0.24) % 1;
          final alpha = math.sin(math.pi * phase) * 0.65;
          _star(
            canvas,
            Offset(
                size.width * (0.30 + i * 0.17) +
                    math.sin(t * math.pi * 2 + i) * 5,
                size.height * (0.70 - phase * 0.42)),
            unit,
            const Color(0xFFFFF9D7).withValues(alpha: alpha),
          );
        }
        break;
      case SquirrelTimeOfDay.day:
        for (var i = 0; i < 3; i++) {
          final phase = (t + i * 0.31) % 1;
          _leaf(
            canvas,
            Offset(
                size.width * (0.61 + i * 0.11) +
                    math.sin(phase * math.pi * 2) * 15,
                size.height * (0.12 + phase * 0.72)),
            unit,
            const Color(0xFF7D9A4A)
                .withValues(alpha: math.sin(math.pi * phase) * 0.8),
          );
        }
        _butterfly(
          canvas,
          Offset(size.width * (0.73 + math.sin(t * math.pi * 2) * 0.06),
              size.height * (0.40 + math.sin(t * math.pi * 4) * 0.04)),
          unit,
          t,
        );
        break;
      case SquirrelTimeOfDay.sunset:
        for (var i = 0; i < 2; i++) {
          final phase = (t + i * 0.25) % 1;
          _bird(
            canvas,
            Offset(size.width * (0.55 + phase * 0.30),
                size.height * (0.25 + i * 0.06)),
            unit,
            const Color(0xFF65415B)
                .withValues(alpha: math.sin(math.pi * phase) * 0.75),
          );
        }
        _fireflies(canvas, size, t, unit, header: true, count: 3);
        break;
      case SquirrelTimeOfDay.night:
        for (var i = 0; i < 5; i++) {
          final glow = 0.30 +
              0.60 *
                  (1 + math.sin((t * (2 + i % 3) + i * 0.18) * math.pi * 2)) /
                  2;
          _star(
            canvas,
            Offset(size.width * (0.52 + i * 0.095),
                size.height * (0.15 + (i % 3) * 0.12)),
            unit * 0.75,
            const Color(0xFFFFF4CA).withValues(alpha: glow),
          );
        }
        _fireflies(canvas, size, t, unit, header: true, count: 4);
        break;
    }
  }

  void _paintSubtleHeader(Canvas canvas, Size size, double t, double unit) {
    switch (timeOfDay) {
      case SquirrelTimeOfDay.morning:
        final glow = (1 + math.sin(t * math.pi * 2)) / 2;
        _star(canvas, Offset(size.width * 0.78, size.height * 0.67), unit,
            const Color(0xFFFFF9D7).withValues(alpha: glow * 0.42));
        break;
      case SquirrelTimeOfDay.day:
        final phase = t % 1;
        _leaf(
          canvas,
          Offset(size.width * (0.75 + math.sin(t * math.pi * 2) * 0.025),
              size.height * (0.12 + phase * 0.6)),
          unit,
          const Color(0xFF7D9A4A)
              .withValues(alpha: math.sin(math.pi * phase) * 0.52),
        );
        break;
      case SquirrelTimeOfDay.sunset:
        _fireflies(canvas, size, t, unit * 0.7, header: true, count: 1);
        break;
      case SquirrelTimeOfDay.night:
        for (var i = 0; i < 2; i++) {
          final glow = (1 + math.sin((t + i * 0.37) * math.pi * 2)) / 2;
          _star(
            canvas,
            Offset(size.width * (0.71 + i * 0.16),
                size.height * (0.21 + i * 0.18)),
            unit * 0.75,
            const Color(0xFFFFF4CA).withValues(alpha: 0.20 + glow * 0.35),
          );
        }
        break;
    }
  }

  void _paintCard(Canvas canvas, Size size, double t, double unit) {
    switch (timeOfDay) {
      case SquirrelTimeOfDay.morning:
        for (var i = 0; i < 2; i++) {
          final glow = (1 + math.sin((t + i * 0.42) * math.pi * 4)) / 2;
          _star(
            canvas,
            Offset(size.width * (0.73 + i * 0.18),
                size.height * (0.20 + i * 0.27)),
            unit * 0.7,
            const Color(0xFFFFF5D4).withValues(alpha: glow * 0.65),
          );
        }
        break;
      case SquirrelTimeOfDay.day:
        final phase = t % 1;
        _leaf(
          canvas,
          Offset(size.width * (0.85 + math.sin(t * math.pi * 2) * 0.04),
              size.height * (0.04 + phase * 0.68)),
          unit * 0.85,
          const Color(0xFF79904A)
              .withValues(alpha: math.sin(math.pi * phase) * 0.70),
        );
        break;
      case SquirrelTimeOfDay.sunset:
        _fireflies(canvas, size, t, unit * 0.8, header: false, count: 3);
        break;
      case SquirrelTimeOfDay.night:
        _fireflies(canvas, size, t, unit * 0.8, header: false, count: 4);
        break;
    }
  }

  void _fireflies(Canvas canvas, Size size, double t, double unit,
      {required bool header, required int count}) {
    for (var i = 0; i < count; i++) {
      final xBase = header ? 0.67 + i * 0.075 : 0.77 + i * 0.06;
      final yBase = header ? 0.61 + (i % 2) * 0.11 : 0.17 + (i % 2) * 0.17;
      final x = size.width * xBase + math.sin(t * math.pi * 2 + i) * 5;
      final y = size.height * yBase + math.sin(t * math.pi * 2 + i * 1.7) * 5;
      final alpha =
          0.12 + 0.78 * (1 + math.sin((t * 2 + i * 0.29) * math.pi * 2)) / 2;
      _firefly(canvas, Offset(x, y), unit, alpha);
    }
  }

  void _star(Canvas canvas, Offset at, double unit, Color color) {
    if (color.a <= 0) return;
    final x = at.dx.roundToDouble();
    final y = at.dy.roundToDouble();
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, unit * 3, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x + unit, y - unit, unit, unit * 3), paint);
  }

  void _leaf(Canvas canvas, Offset at, double unit, Color color) {
    if (color.a <= 0) return;
    final x = at.dx.roundToDouble();
    final y = at.dy.roundToDouble();
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(x + unit, y, unit * 2, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x, y + unit, unit * 3, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x, y + unit * 2, unit * 2, unit), paint);
  }

  void _butterfly(Canvas canvas, Offset at, double unit, double t) {
    final wing = 1 + (1 + math.sin(t * math.pi * 8)) / 2;
    final x = at.dx.roundToDouble();
    final y = at.dy.roundToDouble();
    final paint = Paint()..color = const Color(0xFFFFE3A8);
    canvas.drawRect(
        Rect.fromLTWH(x - wing * unit * 2, y, wing * unit * 2, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x + unit, y, wing * unit * 2, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x, y, unit, unit * 2),
        Paint()..color = const Color(0xFF665D4A));
  }

  void _bird(Canvas canvas, Offset at, double unit, Color color) {
    if (color.a <= 0) return;
    final x = at.dx.roundToDouble();
    final y = at.dy.roundToDouble();
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(x, y, unit * 2, unit), paint);
    canvas.drawRect(
        Rect.fromLTWH(x + unit * 2, y + unit, unit * 2, unit), paint);
    canvas.drawRect(Rect.fromLTWH(x + unit * 4, y, unit * 2, unit), paint);
  }

  void _firefly(Canvas canvas, Offset at, double unit, double alpha) {
    final x = at.dx.roundToDouble();
    final y = at.dy.roundToDouble();
    canvas.drawRect(
      Rect.fromLTWH(x - unit, y - unit, unit * 3, unit * 3),
      Paint()..color = const Color(0xFFE6F6A6).withValues(alpha: alpha * 0.3),
    );
    canvas.drawRect(
      Rect.fromLTWH(x, y, unit, unit),
      Paint()..color = const Color(0xFFFFF4A5).withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(_SquirrelParticlePainter oldDelegate) =>
      timeOfDay != oldDelegate.timeOfDay || area != oldDelegate.area;
}
