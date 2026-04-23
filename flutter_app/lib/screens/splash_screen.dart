import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../domain/onboarding/onboarding_route_selector.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // 2초 후 온보딩 상태에 따라 Home 또는 미완료 단계로 이동
    Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final state = await OnboardingLocalStorage.load();
      final path = OnboardingRouteSelector.resolveStartPath(state);
      if (!mounted) return;
      context.go(path);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Stack(
          children: [
            _buildGlowDecorations(),
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: AppColors.orbitPrimaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.orbitPrimary
                                      .withValues(alpha: 0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.timeline_rounded,
                                size: 58,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Routine Timer',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Design your daily rhythm',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowDecorations() {
    return Stack(
      children: [
        _buildFloatingDot(AppColors.orbitHalo, 0.08, 0.18, 2.0, 18),
        _buildFloatingDot(AppColors.orbitSecondary, 0.78, 0.28, 2.5, 22),
        _buildFloatingDot(AppColors.orbitAccent, 0.24, 0.74, 3.0, 16),
        _buildFloatingDot(AppColors.orbitHalo, 0.66, 0.62, 2.2, 20),
        _buildFloatingDot(AppColors.orbitPrimary, 0.48, 0.12, 2.8, 14),
        _buildFloatingDot(AppColors.orbitSecondary, 0.32, 0.84, 2.4, 12),
      ],
    );
  }

  Widget _buildFloatingDot(
    Color color,
    double left,
    double top,
    double duration,
    double size,
  ) {
    return Positioned(
      left: MediaQuery.of(context).size.width * left,
      top: MediaQuery.of(context).size.height * top,
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 0, end: 1),
        duration: Duration(milliseconds: (duration * 1000).toInt()),
        curve: Curves.easeInOut,
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -20 * (value - 0.5).abs()),
            child: Opacity(
              opacity: 0.24 + (0.32 * value),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.22),
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
