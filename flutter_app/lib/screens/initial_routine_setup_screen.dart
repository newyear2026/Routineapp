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
        showDecor: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 28, 30, 22),
              child: Column(
                children: [
                  const Text('루틴 선택', style: AppTextStyles.titleScreen),
                  const SizedBox(height: 20),
                  const Text('하루의 첫 블록을 골라보세요', style: AppTextStyles.hero),
                  const SizedBox(height: 10),
                  const Text(
                    '처음 시작할 때 넣어둘 기본 루틴만 골라주세요.\n나중에 언제든 수정할 수 있어요.',
                    style: AppTextStyles.helper,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentLavender.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(AppRadii.chip),
                    ),
                    child: Text(
                      '$selectedCount개 선택됨',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 30),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 12),
              child: AppButton(
                label: '나중에 설정할게요',
                onPressed: _skipRoutineSetup,
                variant: AppButtonVariant.ghost,
                expand: false,
                height: 40,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
              child: AppButton(
                label: selectedCount == 0 ? '루틴 없이 시작하기' : '완료하기',
                onPressed: _completeSetup,
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
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _toggleRoutine(index),
          borderRadius: BorderRadius.circular(22),
          child: AppCard(
            variant:
                isSelected ? AppCardVariant.elevated : AppCardVariant.standard,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? color : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? color
                          : AppColors.textMuted.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color, color.withValues(alpha: 0.7)],
                    ),
                  ),
                  child: Center(
                    child:
                        Text(def.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(def.title, style: AppTextStyles.bodyStrong),
                      const SizedBox(height: 4),
                      Text(def.timeLabel, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (def.showRecommendedBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentPink.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '추천',
                      style: AppTextStyles.captionTight.copyWith(
                        color: AppColors.accentPink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
