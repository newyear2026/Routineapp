import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// 부드러운 광원 기반 배경 장식
class HomeDecorativeBackground extends StatelessWidget {
  const HomeDecorativeBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -80,
          left: -30,
          child: _GlowOrb(
            size: 220,
            colors: [
              Color(0x26D9D1F2),
              Color(0x10F2C14E),
              Colors.transparent,
            ],
          ),
        ),
        const Positioned(
          top: 140,
          right: -50,
          child: _GlowOrb(
            size: 190,
            colors: [
              Color(0x18E5866B),
              Color(0x08E5866B),
              Colors.transparent,
            ],
          ),
        ),
        const Positioned(
          bottom: -70,
          left: 40,
          child: _GlowOrb(
            size: 240,
            colors: [
              Color(0x14D9D1F2),
              Color(0x08FFFFFF),
              Colors.transparent,
            ],
          ),
        ),
        ...List.generate(7, (i) => _FloatingParticle(seed: i)),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _FloatingParticle extends StatelessWidget {
  const _FloatingParticle({required this.seed});

  final int seed;

  @override
  Widget build(BuildContext context) {
    final r = math.Random(seed);
    final left = r.nextDouble() * 360;
    final top = r.nextDouble() * 720;
    final size = 5.0 + r.nextDouble() * 6;
    final color = [
      AppColors.orbitPrimary.withValues(alpha: 0.12),
      AppColors.orbitSecondary.withValues(alpha: 0.1),
      AppColors.textMuted.withValues(alpha: 0.08),
    ][r.nextInt(3)];

    return Positioned(
      left: left,
      top: top,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 2000 + r.nextInt(1000)),
        curve: Curves.easeInOut,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 20 * math.sin(value * 2 * math.pi)),
            child: Opacity(
              opacity: 0.25 + 0.55 * math.sin(value * math.pi).abs(),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
