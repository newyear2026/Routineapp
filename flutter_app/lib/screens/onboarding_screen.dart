import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: '하루가 한눈에 보이도록',
      description: '원형 타임라인으로 오늘의 흐름과 지금 해야 할 루틴을 바로 확인해요.',
      accentLabel: '홈 미리보기',
      gradientColors: [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
      preview: _OnboardingPreviewType.timeline,
    ),
    _OnboardingPage(
      title: '루틴 순간마다 바로 반응',
      description: '알림을 받고 완료, 나중에, 건너뛰기까지 빠르게 처리할 수 있어요.',
      accentLabel: '알림과 액션',
      gradientColors: [Color(0xFFE8DDFA), Color(0xFFD4C5F0)],
      preview: _OnboardingPreviewType.notification,
    ),
    _OnboardingPage(
      title: '작은 달성도 매일 쌓이도록',
      description: '오늘의 진행률과 캐릭터 피드백으로 꾸준함을 유지할 수 있어요.',
      accentLabel: '진행률 요약',
      gradientColors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
      preview: _OnboardingPreviewType.progress,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishIntro();
    }
  }

  Future<void> _finishIntro() async {
    await OnboardingLocalStorage.markIntroSeen();
    if (!mounted) return;
    context.go('/routine-setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 72),
                        Text(
                          'Routine Timer',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.76),
                          ),
                        ),
                        AppButton(
                          label: '건너뛰기',
                          onPressed: _finishIntro,
                          variant: AppButtonVariant.ghost,
                          expand: false,
                          height: 40,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _buildPageContent(_pages[index]);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxxl,
                      AppSpacing.lg,
                      AppSpacing.xxxl,
                      AppSpacing.xxxl,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pages.length,
                            (index) => _buildDot(index),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        AppButton(
                          label: _currentPage == _pages.length - 1
                              ? '시작하기'
                              : '다음',
                          onPressed: _nextPage,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: page.gradientColors.first.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                page.accentLabel,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _OnboardingPreviewCard(page: page),
          const SizedBox(height: 28),
          Text(
            page.title,
            style: AppTextStyles.hero,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            page.description,
            style: AppTextStyles.helper,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.accentLavender
            : AppColors.accentLavender.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.accentLabel,
    required this.gradientColors,
    required this.preview,
  });

  final String title;
  final String description;
  final String accentLabel;
  final List<Color> gradientColors;
  final _OnboardingPreviewType preview;
}

enum _OnboardingPreviewType { timeline, notification, progress }

class _OnboardingPreviewCard extends StatelessWidget {
  const _OnboardingPreviewCard({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.elevated,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: page.gradientColors),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  page.accentLabel,
                  style: AppTextStyles.titleSection.copyWith(fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          switch (page.preview) {
            _OnboardingPreviewType.timeline => const _TimelinePreview(),
            _OnboardingPreviewType.notification => const _NotificationPreview(),
            _OnboardingPreviewType.progress => const _ProgressPreview(),
          },
        ],
      ),
    );
  }
}

class _TimelinePreview extends StatelessWidget {
  const _TimelinePreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.12),
                    width: 14,
                  ),
                ),
              ),
              SizedBox(
                width: 92,
                height: 92,
                child: CircularProgressIndicator(
                  value: 0.66,
                  strokeWidth: 14,
                  backgroundColor: AppColors.textMuted.withValues(alpha: 0.12),
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.accentPink.withValues(alpha: 0.92),
                  ),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('☀️', style: TextStyle(fontSize: 24)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(child: _MiniStatChip(label: '07:00 기상')),
            SizedBox(width: 8),
            Expanded(child: _MiniStatChip(label: '08:00 스트레칭')),
          ],
        ),
      ],
    );
  }
}

class _NotificationPreview extends StatelessWidget {
  const _NotificationPreview();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _PreviewMessageCard(
          leading: '🔔',
          title: '기상 시간이에요!',
          subtitle: '완료하거나 잠시 미뤄둘 수 있어요',
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MiniActionButton(
                label: '완료',
                color: AppColors.actionBlue,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MiniActionButton(
                label: '나중에',
                color: AppColors.warning,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _MiniActionButton(
                label: '건너뛰기',
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProgressPreview extends StatelessWidget {
  const _ProgressPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentPink.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      '68%',
                      style: AppTextStyles.statMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('오늘 진행률', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentLavender.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text('🐻', style: TextStyle(fontSize: 28)),
                    SizedBox(height: 4),
                    Text('좋은 흐름이에요', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const _PreviewMessageCard(
          leading: '✨',
          title: '3개 완료',
          subtitle: '남은 루틴도 차분하게 이어가요',
        ),
      ],
    );
  }
}

class _PreviewMessageCard extends StatelessWidget {
  const _PreviewMessageCard({
    required this.leading,
    required this.title,
    required this.subtitle,
  });

  final String leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Text(leading, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  const _MiniActionButton({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  const _MiniStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accentLavender.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
