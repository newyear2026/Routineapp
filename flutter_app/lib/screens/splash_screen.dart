import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../domain/onboarding/onboarding_route_selector.dart';

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF8F3),
              Color(0xFFFFF5F8),
              Color(0xFFF5F0FF),
            ],
          ),
        ),
        child: Stack(
          children: [
            // 배경 데코레이션
            _buildFloatingEmojis(),
            
            // 중앙 로고
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
                          // 로고 아이콘
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFFFE4E9),
                                  Color(0xFFFFD4E0),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFB8C6).withOpacity(0.4),
                                  blurRadius: 30,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                '🐻',
                                style: TextStyle(fontSize: 60),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 앱 이름
                          const Text(
                            'Routine Timer',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8B7B9E),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // 서브 텍스트
                          const Text(
                            '오늘도 함께 해요 💕',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFFB8A4C9),
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

  Widget _buildFloatingEmojis() {
    return Stack(
      children: [
        _buildFloatingEmoji('⭐', 0.1, 0.2, 2.0, 12),
        _buildFloatingEmoji('✨', 0.8, 0.3, 2.5, 16),
        _buildFloatingEmoji('💕', 0.2, 0.7, 3.0, 14),
        _buildFloatingEmoji('🌟', 0.7, 0.6, 2.2, 18),
        _buildFloatingEmoji('💫', 0.5, 0.15, 2.8, 14),
        _buildFloatingEmoji('✨', 0.3, 0.8, 2.4, 12),
      ],
    );
  }

  Widget _buildFloatingEmoji(
    String emoji,
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
              opacity: 0.3 + (0.4 * value),
              child: Text(
                emoji,
                style: TextStyle(fontSize: size),
              ),
            ),
          );
        },
      ),
    );
  }
}
