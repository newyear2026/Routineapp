import 'package:flutter/material.dart';

import '../../models/home_models.dart';
import '../../theme/home_theme.dart';
import 'circular_timetable_area.dart';

/// 원형 시간표 영역 — 홈 화면용 리디자인 섹션
class HomeTimelineSection extends StatelessWidget {
  const HomeTimelineSection({
    super.key,
    required this.segments,
    required this.clockTime,
    required this.centerRoutineName,
    required this.activeRoutineForRing,
    required this.isEmpty,
    this.statusLabel,
    this.nextRoutine,
  });

  final List<RoutineSegment> segments;
  final TimeOfDay clockTime;
  final String centerRoutineName;
  final CurrentRoutine? activeRoutineForRing;
  final bool isEmpty;
  final String? statusLabel;
  final NextRoutine? nextRoutine;

  @override
  Widget build(BuildContext context) {
    if (isEmpty || segments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          gradient: AppColors.orbitCardGradient,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.orbitBorder),
        ),
        child: Column(
          children: [
            Text(
              'TODAY ORBIT',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.84),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '오늘은 비어 있는 하루예요',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textStrong,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.7,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 루틴을 추가하면 하루의 흐름이 원형 시간표에 채워집니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: HomeTheme.textMuted.withValues(alpha: 0.86),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final headerTitle = _headerTitle();
    final headerSubtitle = _headerSubtitle();
    final activeLabel = activeRoutineForRing?.name ?? centerRoutineName;
    final activeEmoji = activeRoutineForRing?.emoji ?? '⏳';
    final activeWindow = activeRoutineForRing == null
        ? null
        : '${activeRoutineForRing!.startTime} - ${activeRoutineForRing!.endTime}';

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        gradient: AppColors.orbitCardGradient,
        borderRadius: BorderRadius.circular(32),
        border:
            Border.all(color: AppColors.orbitBorder.withValues(alpha: 0.92)),
        boxShadow: [
          BoxShadow(
            color: AppColors.orbitPrimary.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY ORBIT',
            style: TextStyle(
              color: HomeTheme.textMuted.withValues(alpha: 0.84),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            headerTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: AppColors.textStrong,
              height: 1.12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            headerSubtitle,
            style: TextStyle(
              color: HomeTheme.textMuted.withValues(alpha: 0.86),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: CircularTimetableArea(
              routines: segments,
              currentTime: clockTime,
              activeRoutine: activeRoutineForRing,
              centerRoutineName: centerRoutineName,
              size: 292,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  icon: activeEmoji,
                  label: '현재 블록',
                  value: activeLabel,
                  helper: activeWindow ?? '지금 처리해야 할 루틴입니다',
                  tone: _InfoPillTone.primary,
                ),
              ),
              if (nextRoutine != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoPill(
                    icon: nextRoutine!.emoji,
                    label: '다음 전환',
                    value: nextRoutine!.name,
                    helper: nextRoutine!.time,
                    tone: _InfoPillTone.warm,
                  ),
                ),
              ],
            ],
          ),
          if (statusLabel != null && statusLabel!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              statusLabel!,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted.withValues(alpha: 0.88),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _headerTitle() {
    if (activeRoutineForRing != null) {
      return '${activeRoutineForRing!.name}에 집중하는 시간';
    }
    if (nextRoutine != null) {
      return '${nextRoutine!.name}까지 흐름을 정리해요';
    }
    return '오늘의 흐름을 한눈에 확인하세요';
  }

  String _headerSubtitle() {
    if (statusLabel != null && statusLabel!.trim().isNotEmpty) {
      return statusLabel!;
    }
    if (activeRoutineForRing != null) {
      return '원형 시간표로 현재 블록과 다음 전환 시점을 또렷하게 보여줍니다.';
    }
    if (nextRoutine != null) {
      return '${nextRoutine!.time}에 ${nextRoutine!.name} 루틴이 시작됩니다.';
    }
    return '하루 전체 루틴 블록을 원형으로 정리해보세요.';
  }
}

enum _InfoPillTone { primary, warm, soft }

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.helper,
    this.tone = _InfoPillTone.primary,
  });

  final String icon;
  final String label;
  final String value;
  final String helper;
  final _InfoPillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _InfoPillTone.primary => (
          bg: AppColors.orbitHalo.withValues(alpha: 0.18),
          border: AppColors.orbitPrimary.withValues(alpha: 0.18),
        ),
      _InfoPillTone.warm => (
          bg: AppColors.orbitSecondary.withValues(alpha: 0.10),
          border: AppColors.orbitSecondary.withValues(alpha: 0.18),
        ),
      _InfoPillTone.soft => (
          bg: AppColors.orbitSurfaceSoft.withValues(alpha: 0.9),
          border: AppColors.orbitBorder,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: HomeTheme.textMuted.withValues(alpha: 0.84),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textStrong,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.24,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            helper,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.captionTight.copyWith(
              color: HomeTheme.textMuted.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}
