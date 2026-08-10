import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../models/home_models.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/routine_palette.dart';
import '../widgets/ds/ds.dart';
import '../widgets/home/circular_timetable_area.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// 카피는 실제 동작만 약속한다.
  ///
  /// 알림에는 액션 버튼이 없다 (`RoutineNotificationService`는 예약만 한다).
  /// "알림에서 바로 완료"처럼 앱이 못 하는 일을 적지 않는다.
  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      title: '지금 할 루틴이 바로 보이게',
      description: '하루 24시간을 원으로 펼쳐 지금 어디쯤인지 한눈에 보여줘요.',
      accentLabel: '홈 화면',
      preview: _OnboardingPreviewType.orbit,
    ),
    _OnboardingPage(
      title: '루틴 순간마다 빠르게 처리',
      description: '알림이 때를 알려주면 홈에서 완료·나중에·스킵으로 정리해요.',
      accentLabel: '알림과 액션',
      preview: _OnboardingPreviewType.actions,
    ),
    _OnboardingPage(
      title: '작은 달성을 꾸준함으로',
      description: '완료·진행 중·예정을 나눠 보여줘 오늘 흐름을 놓치지 않아요.',
      accentLabel: '진행 화면',
      preview: _OnboardingPreviewType.progress,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
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
      body: AppScreenShell(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              // 좌: 브랜드 / 우: 건너뛰기. 가운데 정렬을 위한 폭 하드코딩을 없앤다.
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '하루 루틴 시간표',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppButton(
                    label: '건너뛰기',
                    onPressed: _finishIntro,
                    variant: AppButtonVariant.ghost,
                    expand: false,
                    height: 44,
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _pages.length,
                itemBuilder: (context, index) => _PageContent(
                  page: _pages[index],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.xxl,
                AppSpacing.xxxl,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, _buildDot),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    key: const Key('onboarding-next-button'),
                    label: _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                    onPressed: _nextPage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    final isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        // orbitBorder도 페이지 배경 위에서 1.22:1이라 비활성 점이 보이지 않는다.
        // 비텍스트 요소 기준(WCAG 1.4.11) 3:1을 넘기려면 이 정도는 필요하다.
        color: isActive
            ? AppColors.orbitPrimary
            : AppColors.textMuted.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    // 화면이 남으면 가운데로 모으고, 모자라면 스크롤한다.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orbitPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    page.accentLabel,
                    style: AppTextStyles.captionTight.copyWith(
                      color: AppColors.orbitPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _PreviewCard(preview: page.preview),
              const SizedBox(height: AppSpacing.xxl),
              Text(page.title, style: AppTextStyles.titleScreen),
              const SizedBox(height: AppSpacing.sm),
              Text(page.description, style: AppTextStyles.helper),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.title,
    required this.description,
    required this.accentLabel,
    required this.preview,
  });

  final String title;
  final String description;
  final String accentLabel;
  final _OnboardingPreviewType preview;
}

enum _OnboardingPreviewType { orbit, actions, progress }

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.preview});

  final _OnboardingPreviewType preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appSurfaceDecoration(radius: AppRadii.cardLarge),
      child: switch (preview) {
        _OnboardingPreviewType.orbit => const _OrbitPreview(),
        _OnboardingPreviewType.actions => const _ActionsPreview(),
        _OnboardingPreviewType.progress => const _ProgressPreview(),
      },
    );
  }
}

/// 홈과 **같은 위젯**을 쓴다. 별도 목업을 그리면 실제 화면과 어긋난다.
class _OrbitPreview extends StatelessWidget {
  const _OrbitPreview();

  static const _sample = <RoutineSegment>[
    RoutineSegment(
      id: 'wake',
      startMinutesFromMidnight: 7 * 60,
      endMinutesFromMidnight: 8 * 60,
      label: '기상',
      emoji: '',
      color: RoutinePalette.coral,
    ),
    RoutineSegment(
      id: 'focus',
      startMinutesFromMidnight: 10 * 60,
      endMinutesFromMidnight: 12 * 60,
      label: '집중',
      emoji: '',
      color: RoutinePalette.lavender,
    ),
    RoutineSegment(
      id: 'dinner',
      startMinutesFromMidnight: 18 * 60,
      endMinutesFromMidnight: 19 * 60,
      label: '저녁식사',
      emoji: '',
      color: RoutinePalette.amber,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularTimetableArea(
        routines: _sample,
        currentTime: TimeOfDay(hour: 10, minute: 40),
        size: 200,
      ),
    );
  }
}

/// 홈 하단 액션 바와 같은 구성 — 라벨도 실제와 동일하게 '스킵'을 쓴다.
class _ActionsPreview extends StatelessWidget {
  const _ActionsPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.orbitSurfaceSoft,
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_rounded,
                color: AppColors.orbitPrimary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '기상 시간이에요',
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    const Text('07:00', style: AppTextStyles.captionTight),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: '기상 완료하기',
          icon: Icons.check_rounded,
          height: 46,
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: '나중에',
                variant: AppButtonVariant.secondary,
                height: 40,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: '스킵',
                variant: AppButtonVariant.ghost,
                height: 40,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 진행 화면의 hero + 상태 그룹과 같은 구성.
class _ProgressPreview extends StatelessWidget {
  const _ProgressPreview();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3 / 5', style: AppTextStyles.statHero),
                  const SizedBox(height: 6),
                  Text(
                    '좋은 흐름이에요',
                    style: AppTextStyles.titleSection.copyWith(
                      fontSize: 15,
                      color: AppColors.orbitPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 0.6,
                    strokeWidth: 8,
                    backgroundColor: AppColors.orbitHalo,
                    valueColor: AlwaysStoppedAnimation(AppColors.orbitPrimary),
                  ),
                  Text('60%', style: AppTextStyles.captionTight),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Row(
          children: [
            Expanded(
              child: _StatusChip(
                label: '완료',
                count: '3',
                tint: AppColors.success,
                textColor: AppColors.successText,
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _StatusChip(
                label: '예정',
                count: '2',
                tint: AppColors.orbitAccent,
                textColor: AppColors.scheduledText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.count,
    required this.tint,
    required this.textColor,
  });

  final String label;
  final String count;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.chip),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            count,
            style: AppTextStyles.bodyStrong.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
}
