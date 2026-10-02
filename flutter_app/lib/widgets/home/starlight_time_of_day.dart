import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/store/character_pack_catalog.dart';
import '../../theme/pack_skin.dart';
import '../../theme/pack_skin_catalog.dart';

/// 기본 별빛 고양이 팩의 하늘. 네 탭이 같은 기기 시각으로 장면을 고른다.
enum StarlightTimeOfDay {
  morning,
  day,
  sunset,
  night;

  static StarlightTimeOfDay fromHour(int hour) =>
      values[PackScenePhase.fromHour(hour).index];

  static PackTimedScene get _scene =>
      PackSkinCatalog.of(CharacterPackCatalog.starlightCat).timedScene!;

  String get headerAsset => _scene.headers[index];

  String get cardAsset => _scene.cards[index];

  bool get hasLightHeaderText => this == night;
}

/// 상단 하늘은 본문 색으로 스며들고, 움직임은 글자 없는 오른쪽에만 둔다.
class StarlightSkyBackdrop extends StatelessWidget {
  const StarlightSkyBackdrop({
    super.key,
    required this.timeOfDay,
    this.subtle = false,
    this.animate = true,
  });

  final StarlightTimeOfDay timeOfDay;
  final bool subtle;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SizedBox(
        width: double.infinity,
        height: 250,
        child: ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (bounds) => const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.white, Colors.transparent],
            stops: [0, 0.57, 1],
          ).createShader(bounds),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: SizedBox.expand(
                  key: ValueKey(timeOfDay),
                  child: Image.asset(
                    timeOfDay.headerAsset,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    filterQuality: FilterQuality.none,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: timeOfDay.hasLightHeaderText
                        ? const [
                            Color(0x550F2058),
                            Color(0x220F2058),
                            Colors.transparent,
                          ]
                        : const [
                            Color(0x99FFF9EF),
                            Color(0x33FFF9EF),
                            Colors.transparent,
                          ],
                    stops: const [0, 0.42, 0.78],
                  ),
                ),
              ),
              if (animate)
                StarlightSkySparkles(
                  timeOfDay: timeOfDay,
                  subtle: subtle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StarlightSkySparkles extends StatefulWidget {
  const StarlightSkySparkles({
    super.key,
    required this.timeOfDay,
    this.subtle = false,
  });

  final StarlightTimeOfDay timeOfDay;
  final bool subtle;

  @override
  State<StarlightSkySparkles> createState() => _StarlightSkySparklesState();
}

class _StarlightSkySparklesState extends State<StarlightSkySparkles>
    with WidgetsBindingObserver {
  Timer? _motion;
  int _frame = 0;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(StarlightSkySparkles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtle != widget.subtle) {
      _motion?.cancel();
      _motion = null;
      _syncMotion();
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
    if (enabled && _motion == null) {
      _motion = Timer.periodic(
        Duration(milliseconds: widget.subtle ? 1400 : 700),
        (_) {
          if (mounted) setState(() => _frame++);
        },
      );
    } else if (!enabled && _motion != null) {
      _motion!.cancel();
      _motion = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _motion?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _StarlightSparklePainter(
            timeOfDay: widget.timeOfDay,
            subtle: widget.subtle,
            frame: _frame,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _StarlightSparklePainter extends CustomPainter {
  _StarlightSparklePainter({
    required this.timeOfDay,
    required this.subtle,
    required this.frame,
  });

  final StarlightTimeOfDay timeOfDay;
  final bool subtle;
  final int frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = subtle ? 2 : 4;
    final step = (math.min(size.width / 390, size.height / 250) * 2.5)
        .round()
        .clamp(2, 4)
        .toDouble();
    for (var i = 0; i < count; i++) {
      final phase = frame / 12 * (1 + i % 2) + i * 0.23;
      final glow = (1 + math.sin(phase * math.pi * 2)) / 2;
      final alpha = (timeOfDay == StarlightTimeOfDay.night ? 0.25 : 0.08) +
          glow * (subtle ? 0.26 : 0.48);
      final x = size.width * (0.58 + i * 0.105);
      final y = size.height * (0.17 + (i % 3) * 0.16);
      final color = (timeOfDay == StarlightTimeOfDay.night
              ? const Color(0xFFFFF4C7)
              : const Color(0xFFFFD571))
          .withValues(alpha: alpha);
      final paint = Paint()..color = color;
      final center = Offset(x, y);
      canvas.drawRect(
          Rect.fromCenter(center: center, width: step, height: step), paint);
      canvas.drawRect(
          Rect.fromCenter(center: center, width: step * 3, height: step),
          paint);
      canvas.drawRect(
          Rect.fromCenter(center: center, width: step, height: step * 3),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StarlightSparklePainter oldDelegate) =>
      oldDelegate.timeOfDay != timeOfDay ||
      oldDelegate.subtle != subtle ||
      oldDelegate.frame != frame;
}
