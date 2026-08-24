import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 루틴 폼의 상단 바.
///
/// 저장은 하단 CTA 하나만 맡는다 (UI_STANDARDS 2: 화면당 Primary 1개).
class RoutineFormHeader extends StatelessWidget {
  const RoutineFormHeader({
    super.key,
    required this.title,
    required this.onBack,
    this.onDelete,
  });

  final String title;
  final VoidCallback onBack;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Row(
        children: [
          IconButton(
            tooltip: AppLocalizations.of(context).commonBack,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleScreen,
            ),
          ),
          SizedBox(
            width: 54,
            child: onDelete == null
                ? null
                : IconButton(
                    tooltip: AppLocalizations.of(context).routineDeleteTitle,
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.dangerText,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 폼 섹션을 감싸는 흰 서피스.
class RoutineFormSurface extends StatelessWidget {
  const RoutineFormSurface({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.orbitSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.orbitBorder),
      ),
      child: child,
    );
  }
}

/// 시작·종료 시각 타일.
class RoutineTimeTile extends StatelessWidget {
  const RoutineTimeTile({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final TimeOfDay value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.orbitSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.orbitBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                TimeMinutes.formatTimeOfDay(value),
                style: AppTextStyles.titleSection.copyWith(fontSize: 25),
              ),
              const SizedBox(height: 3),
              Text(label, style: AppTextStyles.caption),
            ],
          ),
        ),
      ),
    );
  }
}

/// 반복 요일 하나.
class RoutineWeekdayCircle extends StatelessWidget {
  const RoutineWeekdayCircle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: AppLocalizations.of(context).weekdayFullSuffix(label),
      child: InkWell(
        key: Key('routine-weekday-$label'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 39,
            height: 39,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.orbitPrimary.withValues(alpha: .15)
                  : AppColors.orbitSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    selected ? AppColors.orbitPrimary : AppColors.orbitBorder,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.bodyStrong.copyWith(
                color:
                    selected ? AppColors.orbitPrimary : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 폼 안내 한 줄.
class RoutineFormInfoLine extends StatelessWidget {
  const RoutineFormInfoLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.orbitHalo.withValues(alpha: .24),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_graph_rounded,
            size: 17,
            color: AppColors.orbitPrimary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.orbitPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 이름 입력을 돕는 제안 칩.
class RoutineSuggestionChip extends StatelessWidget {
  const RoutineSuggestionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      avatar: const Icon(Icons.add_rounded, size: 16),
      onPressed: onTap,
      backgroundColor: AppColors.orbitHalo.withValues(alpha: .18),
      side: BorderSide(color: AppColors.orbitPrimary.withValues(alpha: .2)),
      labelStyle: AppTextStyles.caption.copyWith(
        color: AppColors.orbitPrimary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// 다른 루틴과 시간이 겹칠 때의 경고.
class RoutineOverlapNotice extends StatelessWidget {
  const RoutineOverlapNotice({super.key, required this.routine});

  final Routine routine;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.orbitAccent.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: .45)),
      ),
      child: Text(
        AppLocalizations.of(context).routineOverlapInline(routine.title),
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
      ),
    );
  }
}
