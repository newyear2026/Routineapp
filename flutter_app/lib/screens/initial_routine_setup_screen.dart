import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/services/onboarding_routine_setup_service.dart';
import '../domain/onboarding/onboarding_preview_nav.dart';
import '../domain/onboarding/recommended_routine_catalog.dart';
import '../domain/models/routine_icon_id.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../theme/app_pixel_style.dart';

class InitialRoutineSetupScreen extends StatefulWidget {
  const InitialRoutineSetupScreen({
    super.key,
    this.preview = false,
    this.previewFlow = false,
  });

  final bool preview;
  final bool previewFlow;

  @override
  State<InitialRoutineSetupScreen> createState() =>
      _InitialRoutineSetupScreenState();
}

class _InitialRoutineSetupScreenState extends State<InitialRoutineSetupScreen> {
  static const List<RecommendedRoutineDefinition> _catalog =
      RecommendedRoutineCatalog.items;
  final OnboardingRoutineSetupService _onboardingRoutines =
      OnboardingRoutineSetupService();

  late List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List<bool>.from(RecommendedRoutineCatalog.defaultSelection);
  }

  void _toggleRoutine(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }

  List<RecommendedRoutineDefinition> _selectedDefinitions() {
    final out = <RecommendedRoutineDefinition>[];
    for (var i = 0; i < _catalog.length; i++) {
      if (_selected[i]) out.add(_catalog[i]);
    }
    return out;
  }

  Future<void> _completeSetup() async {
    if (widget.preview) {
      if (!mounted) return;
      OnboardingPreviewNav.finish(
        context,
        flow: widget.previewFlow,
        nextPath: OnboardingPreviewNav.notificationFlow,
      );
      return;
    }
    // 저장되는 이름도 지금 보고 있는 언어로 남는다.
    final l10n = AppLocalizations.of(context);
    await _onboardingRoutines.completeWithSelectedDefinitions(
      _selectedDefinitions(),
      (def) => recommendedRoutineTitle(l10n, def),
    );
    if (!mounted) return;
    await context.read<RoutineAppController>().load();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  Future<void> _skipRoutineSetup() async {
    if (widget.preview) {
      if (!mounted) return;
      OnboardingPreviewNav.finish(
        context,
        flow: widget.previewFlow,
        nextPath: OnboardingPreviewNav.notificationFlow,
      );
      return;
    }
    await _onboardingRoutines.skipWithoutSavingRoutines();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedCount = _selected.where((s) => s).length;
    return Scaffold(
      body: AppScreenShell(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.preview)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        tooltip: l10n.commonBack,
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        color: AppColors.textPrimary,
                      ),
                    ),
                  Text(l10n.setupTitle, style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          l10n.setupHeadline,
                          style: AppTextStyles.titleScreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppIcon(
                        Icons.calendar_month_rounded,
                        color: AppColors.orbitPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.setupBody,
                    style: AppTextStyles.helper,
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.orbitPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text(
                        l10n.selectedCount(selectedCount),
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.orbitPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                itemCount: _catalog.length,
                itemBuilder: (context, index) {
                  final def = _catalog[index];
                  return _buildRoutineCard(
                    def: def,
                    index: index,
                    isSelected: _selected[index],
                  );
                },
              ),
            ),
            // Primary가 먼저, Ghost는 그 아래. 알림 권한 화면과 순서를 맞춘다.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
              child: AppButton(
                label: selectedCount == 0
                    ? l10n.setupStartEmpty
                    : l10n.setupFinish,
                onPressed: _completeSetup,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AppButton(
                label: l10n.setupLater,
                onPressed: _skipRoutineSetup,
                variant: AppButtonVariant.ghost,
                expand: false,
                height: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutineCard({
    required RecommendedRoutineDefinition def,
    required int index,
    required bool isSelected,
  }) {
    final color = Color(def.colorValue);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: isSelected,
        label: '${recommendedRoutineTitle(AppLocalizations.of(context), def)}'
            ' ${def.timeLabel}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleRoutine(index),
            borderRadius: BorderRadius.zero,
            child: AnimatedContainer(
              key: Key('routine-choice-${def.catalogId}'),
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              // 선택 상태는 카드가 직접 말한다.
              // AppCard의 variant 차이(모서리·그림자)만으로는 구분되지 않는다.
              decoration: ShapeDecoration(
                // 반투명 보라를 그대로 두면 페이지 배경과 섞여 선택된 쪽이
                // 오히려 어둡고 흐려 보인다. 흰 서피스 위에 합성해 밝게 유지한다.
                color: isSelected
                    ? Color.alphaBlend(
                        AppColors.orbitPrimary.withValues(alpha: 0.07),
                        AppColors.orbitSurface,
                      )
                    : AppColors.orbitSurface,
                shape: AppPixelStyle.shape(
                  color: isSelected
                      ? AppColors.orbitPrimary
                      : AppColors.orbitBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    key: Key('routine-color-${def.catalogId}'),
                    child: RoutineMark(
                      icon: RoutineIconId.fromCatalogId(def.catalogId),
                      color: color,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            recommendedRoutineTitle(
                              AppLocalizations.of(context),
                              def,
                            ),
                            style: AppTextStyles.bodyStrong,
                          ),
                        ),
                        Text(def.timeLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      color: isSelected
                          ? AppColors.orbitPrimary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orbitPrimary
                            : AppColors.textMuted,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const PixelIcon(PixelGlyph.check,
                            size: 20, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 추천 루틴 이름 — 카탈로그는 키만 갖고, 이름은 현재 언어에서 고른다.
String recommendedRoutineTitle(
  AppLocalizations l10n,
  RecommendedRoutineDefinition def,
) {
  switch (def.catalogId) {
    case 'wake':
      return l10n.catalogWakeUp;
    case 'exercise':
      return l10n.catalogExercise;
    case 'breakfast':
      return l10n.catalogBreakfast;
    case 'study':
      return l10n.catalogStudy;
    case 'lunch':
      return l10n.catalogLunch;
    case 'rest':
      return l10n.catalogBreak;
    case 'dinner':
      return l10n.catalogDinner;
    case 'sleep':
      return l10n.catalogSleep;
    default:
      return def.catalogId;
  }
}
