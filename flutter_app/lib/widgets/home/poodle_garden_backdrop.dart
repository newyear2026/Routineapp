import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/pack_skin.dart';

/// 꽃밭 그림은 고정하고 작은 빛·꽃잎·반딧불만 그린다.
class PoodleGardenAtmosphere extends StatefulWidget {
  const PoodleGardenAtmosphere({
    super.key,
    required this.phase,
    this.subtle = false,
    this.card = false,
  });

  final PackScenePhase phase;
  final bool subtle;
  final bool card;

  @override
  State<PoodleGardenAtmosphere> createState() => _PoodleGardenAtmosphereState();
}

class _PoodleGardenAtmosphereState extends State<PoodleGardenAtmosphere>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.subtle ? 12 : 6),
    );
  }

  @override
  void didUpdateWidget(PoodleGardenAtmosphere oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subtle != widget.subtle) {
      _controller.duration = Duration(seconds: widget.subtle ? 12 : 6);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (mounted) _sync();
  }

  void _sync() {
    final enabled = _foreground &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (enabled && !_controller.isAnimating) _controller.repeat();
    if (!enabled && _controller.isAnimating) _controller.stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _PoodleParticlePainter(
            phase: widget.phase,
            subtle: widget.subtle,
            card: widget.card,
            motion: _controller,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _PoodleParticlePainter extends CustomPainter {
  _PoodleParticlePainter({
    required this.phase,
    required this.subtle,
    required this.card,
    required this.motion,
  }) : super(repaint: motion);

  final PackScenePhase phase;
  final bool subtle;
  final bool card;
  final Animation<double> motion;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final count = subtle ? 4 : 8;
    final t = motion.value;
    for (var i = 0; i < count; i++) {
      final seed = i / count;
      // 글자가 있는 왼쪽은 비워 둔다. 카드에서는 꽃밭 오른쪽만 움직인다.
      final baseX = 0.55 + (0.39 * ((i * 0.6180339) % 1));
      final x = size.width * baseX;
      final baseY = card ? 0.25 + seed * 0.57 : 0.2 + seed * 0.65;
      final drift = math.sin((t + seed) * math.pi * 2) * 4;
      final rise = ((t + seed) % 1) * (card ? 17 : 24);
      final y = size.height * baseY + drift - rise;
      final pulse = 0.5 + 0.5 * math.sin((t * 2 + seed) * math.pi * 2);
      final opacity = (subtle ? 0.28 : 0.52) * pulse;
      final paint = Paint()
        ..color = switch (phase) {
          PackScenePhase.morning => const Color(0xFFFFF9D6),
          PackScenePhase.day => const Color(0xFFFFF2B2),
          PackScenePhase.sunset => const Color(0xFFFFDC93),
          PackScenePhase.night => const Color(0xFFFFED9B),
        }
            .withValues(alpha: opacity);
      switch (phase) {
        case PackScenePhase.morning:
          // 이슬과 상승하는 빛.
          canvas.drawRect(Rect.fromLTWH(x, y, 3, 3), paint);
          canvas.drawRect(Rect.fromLTWH(x + 1, y - 2, 1, 7), paint);
        case PackScenePhase.day:
          // 꽃가루와 드문 나비의 두 픽셀 날개.
          canvas.drawRect(Rect.fromLTWH(x, y, 2, 2), paint);
          if (i == 2) {
            canvas.drawRect(Rect.fromLTWH(x - 3, y - 2, 3, 3), paint);
            canvas.drawRect(Rect.fromLTWH(x + 2, y - 2, 3, 3), paint);
          }
        case PackScenePhase.sunset:
          // 꽃잎이 천천히 가라앉는다.
          canvas.drawRect(
              Rect.fromLTWH(x + drift, y + rise * 0.55, 4, 2), paint);
        case PackScenePhase.night:
          // 반딧불의 작은 사각형 빛.
          canvas.drawRect(Rect.fromLTWH(x, y, 3, 3), paint);
          canvas.drawRect(Rect.fromLTWH(x - 2, y + 1, 7, 1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PoodleParticlePainter oldDelegate) =>
      oldDelegate.phase != phase ||
      oldDelegate.subtle != subtle ||
      oldDelegate.card != card;
}

class PoodleGardenBackdrop extends StatelessWidget {
  const PoodleGardenBackdrop({
    super.key,
    required this.phase,
    required this.headerAsset,
    this.subtle = false,
    this.animate = true,
  });

  final PackScenePhase phase;
  final String headerAsset;
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
            stops: [0, 0.54, 1],
          ).createShader(bounds),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                child: SizedBox.expand(
                  key: ValueKey(headerAsset),
                  child: Image.asset(
                    headerAsset,
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
                    colors: phase == PackScenePhase.night
                        ? const [
                            Color(0x99132440),
                            Color(0x33132440),
                            Colors.transparent
                          ]
                        : const [
                            Color(0xAAFFF8E8),
                            Color(0x44FFF8E8),
                            Colors.transparent
                          ],
                    stops: const [0, 0.44, 0.78],
                  ),
                ),
              ),
              if (animate) PoodleGardenAtmosphere(phase: phase, subtle: subtle),
            ],
          ),
        ),
      ),
    );
  }
}
