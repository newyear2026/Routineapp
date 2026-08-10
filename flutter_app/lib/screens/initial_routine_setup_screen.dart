import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../application/services/onboarding_routine_setup_service.dart';
import '../domain/onboarding/recommended_routine_catalog.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

class InitialRoutineSetupScreen extends StatefulWidget {
  const InitialRoutineSetupScreen({super.key});

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
    await _onboardingRoutines.completeWithSelectedDefinitions(
      _selectedDefinitions(),
    );
    if (!mounted) return;
    await context.read<RoutineAppController>().load();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  Future<void> _skipRoutineSetup() async {
    await _onboardingRoutines.skipWithoutSavingRoutines();
    if (!mounted) return;
    context.go('/notification-permission');
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('루틴 선택', style: AppTextStyles.caption),
                  const SizedBox(height: 6),
                  // hero(32)는 이 문장에서 두 줄로 깨진다. 한 줄에 들어가는 크기를 쓴다.
                  const Text(
                    '하루의 첫 블록을 골라보세요',
                    style: AppTextStyles.titleScreen,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '처음 시작할 때 넣어둘 기본 루틴만 골라주세요. 나중에 언제든 수정할 수 있어요.',
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
                        borderRadius: BorderRadius.circular(AppRadii.chip),
                      ),
                      child: Text(
                        '$selectedCount개 선택됨',
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
                label: selectedCount == 0 ? '루틴 없이 시작하기' : '완료하기',
                onPressed: _completeSetup,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: AppButton(
                label: '나중에 설정할게요',
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
        label: '${def.title} ${def.timeLabel}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggleRoutine(index),
            borderRadius: BorderRadius.circular(AppRadii.card),
            child: AnimatedContainer(
              key: Key('routine-choice-${def.catalogId}'),
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(14),
              // 선택 상태는 카드가 직접 말한다.
              // AppCard의 variant 차이(모서리·그림자)만으로는 구분되지 않는다.
              decoration: BoxDecoration(
                // 반투명 보라를 그대로 두면 페이지 배경과 섞여 선택된 쪽이
                // 오히려 어둡고 흐려 보인다. 흰 서피스 위에 합성해 밝게 유지한다.
                color: isSelected
                    ? Color.alphaBlend(
                        AppColors.orbitPrimary.withValues(alpha: 0.07),
                        AppColors.orbitSurface,
                      )
                    : AppColors.orbitSurface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(
                  color: isSelected
                      ? AppColors.orbitPrimary
                      : AppColors.orbitBorder,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // 연한 파스텔 위 흰 체크는 보이지 않는다. 브랜드색으로 채운다.
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
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    key: Key('routine-color-${def.catalogId}'),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(def.title, style: AppTextStyles.bodyStrong),
                        const SizedBox(height: 2),
                        Text(def.timeLabel, style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                  if (def.showRecommendedBadge)
                    const AppStatusBadge(
                      label: '추천',
                      tone: AppStatusBadgeTone.info,
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
