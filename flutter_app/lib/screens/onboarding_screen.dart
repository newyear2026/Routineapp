import '../widgets/ds/pixel_decoration.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../data/local/onboarding_local_storage.dart';
import '../domain/models/routine_icon_id.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/routine_palette.dart';
import '../widgets/ds/ds.dart';
import '../widgets/home/circular_timetable_area.dart';
import '../widgets/home/orbit_brand_mark.dart';

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
  static const _previews = <_OnboardingPreviewType>[
    _OnboardingPreviewType.orbit,
    _OnboardingPreviewType.actions,
    _OnboardingPreviewType.progress,
  ];

  List<_OnboardingPage> _buildPages(AppLocalizations l10n) => [
        _OnboardingPage(
          title: l10n.onboardingPage1Title,
          description: l10n.onboardingPage1Body,
          accentLabel: l10n.onboardingPage1Tag,
          preview: _previews[0],
        ),
        _OnboardingPage(
          title: l10n.onboardingPage2Title,
          description: l10n.onboardingPage2Body,
          accentLabel: l10n.onboardingPage2Tag,
          preview: _previews[1],
        ),
        _OnboardingPage(
          title: l10n.onboardingPage3Title,
          description: l10n.onboardingPage3Body,
          accentLabel: l10n.onboardingPage3Tag,
          preview: _previews[2],
        ),
      ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _nextPage() {
    if (_currentPage < _previews.length - 1) {
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
    final l10n = AppLocalizations.of(context);
    final pages = _buildPages(l10n);
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
                  // 브랜드 문구는 언어마다 길이가 다르다. 건너뛰기 버튼이
                  // 밀려나지 않도록 이쪽이 먼저 줄어든다.
                  Flexible(
                    child: Text(
                      l10n.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: AppButton(
                          label: l10n.commonSkipStep,
                          onPressed: _finishIntro,
                          variant: AppButtonVariant.ghost,
                          expand: false,
                          height: 44,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) => _PageContent(
                  page: pages[index],
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
                  PixelSteps(total: pages.length, current: _currentPage),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    key: const Key('onboarding-next-button'),
                    label: _currentPage == pages.length - 1
                        ? l10n.onboardingStart
                        : l10n.commonNext,
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
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.orbitPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.zero,
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
              Text(page.title, style: AppTextStyles.hero),
              const SizedBox(height: AppSpacing.sm),
              Text(page.description, style: AppTextStyles.helper),
              const SizedBox(height: AppSpacing.xxl),
              _PreviewCard(preview: page.preview),
              const SizedBox(height: AppSpacing.lg),
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
    if (preview == _OnboardingPreviewType.orbit) {
      return const _OrbitPreview();
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth.clamp(0, 280).toDouble();
            return Center(
              child: SizedBox(
                width: size,
                height: size * 0.92,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      top: size * 0.08,
                      child: PixelCloud(width: size * 0.16),
                    ),
                    Positioned(
                      right: 0,
                      top: size * 0.18,
                      child: PixelCloud(width: size * 0.16),
                    ),
                    const Positioned(
                      left: 18,
                      top: 28,
                      child: PixelSpark(size: 12),
                    ),
                    const Positioned(
                      right: 22,
                      top: 40,
                      child: PixelSpark(size: 11),
                    ),
                    CircularTimetableArea(
                      routines: OrbitBrandMark.sampleSegments(l10n),
                      currentTime: const TimeOfDay(hour: 15, minute: 14),
                      size: size * 0.82,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: appSurfaceDecoration(radius: 24),
          child: Row(
            children: [
              RoutineMark(
                icon: RoutineIconId.coffee,
                color: RoutinePalette.blue,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.catalogBreak,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSection,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '15:00-16:00',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.timingUntilEnd(l10n.durationMinutes(46)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.captionTight.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 홈 하단 액션 바와 같은 구성 — 라벨도 실제와 동일하게 '건너뛰기'를 쓴다.
class _ActionsPreview extends StatelessWidget {
  const _ActionsPreview();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        const PixelDecoration(asset: 'bell', size: 56),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: appSurfaceDecoration(radius: 16),
          child: Row(
            children: [
              const PixelDecoration(asset: 'bell', size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('07:00', style: AppTextStyles.captionTight),
                    const SizedBox(height: 2),
                    Text(
                      l10n.onboardingDemoWakeAlert,
                      style: AppTextStyles.smallStrong,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: AppColors.orbitSurfaceSoft,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              RoutineMark(
                icon: RoutineIconId.sun,
                color: RoutinePalette.coral,
                size: 40,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingDemoWake,
                      style: AppTextStyles.smallStrong,
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
          label: l10n.onboardingDemoWakeAction,
          icon: Icons.check_rounded,
          height: 46,
          onPressed: () {},
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: l10n.statusSnoozed,
                variant: AppButtonVariant.secondary,
                height: 40,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppButton(
                label: l10n.actionSkip,
                variant: AppButtonVariant.secondary,
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
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Row(
          children: [
            const Text('3 / 5', style: AppTextStyles.statHero),
            const Spacer(),
            const Text('60%', style: AppTextStyles.statMedium),
          ],
        ),
        const SizedBox(height: 10),
        SegmentedProgress(
          value: 0.6,
          segmentCount: 5,
          semanticLabel: l10n.progressSemantic(60),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.onboardingDemoGoodFlow,
          style: AppTextStyles.caption.copyWith(color: AppColors.orbitPrimary),
        ),
        const SizedBox(height: 14),
        _PreviewStatusRow(
          icon: Icons.check_rounded,
          tint: AppColors.success,
          textColor: AppColors.successText,
          title: l10n.statusCompleted,
          subtitle: l10n.progressHeroAllDoneBody,
        ),
        const SizedBox(height: 8),
        _PreviewStatusRow(
          icon: Icons.schedule_rounded,
          tint: AppColors.orbitPrimary,
          textColor: AppColors.activeText,
          title: l10n.statusInProgress,
          subtitle: l10n.progressGroupActiveEmpty,
        ),
        const SizedBox(height: 8),
        _PreviewStatusRow(
          icon: Icons.wb_sunny_outlined,
          tint: AppColors.orbitAccent,
          textColor: AppColors.scheduledText,
          title: l10n.statusUpcoming,
          subtitle: l10n.progressGroupUpcomingEmpty,
        ),
      ],
    );
  }
}

class _PreviewStatusRow extends StatelessWidget {
  const _PreviewStatusRow({
    required this.icon,
    required this.tint,
    required this.textColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color tint;
  final Color textColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: appSurfaceDecoration(radius: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: AppIcon(icon, size: 16, color: textColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyStrong),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          const AppIcon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

