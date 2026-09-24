import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../domain/onboarding/onboarding_preview_nav.dart';
import '../domain/onboarding/onboarding_route_selector.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/pixel_steps.dart';
import '../widgets/home/orbit_brand_mark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.preview = false,
    this.previewFlow = false,
  });

  /// 설정 미리보기 — 온보딩 상태를 읽거나 바꾸지 않는다.
  final bool preview;

  /// 미리보기 전체 흐름의 첫 화면. 2초 뒤 시작 안내 미리보기로 이어진다.
  final bool previewFlow;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _advance;

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

    _advance = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      if (widget.preview) {
        if (widget.previewFlow) {
          context.push(OnboardingPreviewNav.introFlow);
        }
        return;
      }
      final state = await OnboardingLocalStorage.load();
      final path = OnboardingRouteSelector.resolveStartPath(state);
      if (!mounted) return;
      context.go(path);
    });
  }

  @override
  void dispose() {
    _advance?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: Stack(
          children: [
            _buildGlowDecorations(),
            if (widget.preview)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    key: const Key('splash-preview-back'),
                    tooltip: l10n.commonBack,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
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
                          const OrbitBrandMark(size: 228),
                          const SizedBox(height: AppSpacing.xxl),
                          Text(
                            l10n.appName,
                            style: AppTextStyles.hero,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            l10n.appTagline,
                            style: AppTextStyles.label,
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          const PixelSteps(total: 3, current: 0),
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
