import 'package:flutter/material.dart';

import '../../application/home/home_snapshot.dart';
import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/services/routine_day_service.dart';
import '../../domain/services/routine_state_resolver.dart';
import '../../domain/utils/time_minutes.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme_preset.dart';
import '../ds/animated_cat.dart';
import '../ds/app_status_badge.dart';
import '../ds/pixel_digits.dart';
import '../ds/routine_mark.dart';

/// 루틴 탭 «오늘» — 오늘 루틴을 시간 레일 위에 늘어놓는다.
///
/// 홈 원판의 색 호가 왼쪽 레일의 점으로 이어진다. 배지는 홈 첫 카드와 같은
/// 규칙(UI_STANDARDS «Home 첫 카드»)을 따르고, 지금 루틴만 위젯과 같은
/// 그라데이션 카드에 고양이를 태운다. 완료에 취소선을 쓰지 않는다.
class RoutineTodayTimeline extends StatelessWidget {
  const RoutineTodayTimeline({
    super.key,
    required this.home,
    required this.logsToday,
    required this.now,
    required this.onOpen,
  });

  final HomeSnapshot home;
  final List<RoutineLog> logsToday;
  final DateTime now;
  final ValueChanged<Routine> onOpen;

  @override
  Widget build(BuildContext context) {
    final routines = home.todayRoutines;
    const days = RoutineDayService();
    final statuses = [
      for (final routine in routines)
        RoutineStateResolver.effectiveStatus(
          routine: routine,
          log: days.logForRoutine(routine.id, logsToday),
          nowLocal: now,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Summary(routines: routines, statuses: statuses),
        const SizedBox(height: 14),
        for (var i = 0; i < routines.length; i++)
          _TimelineItem(
            routine: routines[i],
            status: statuses[i],
            isCurrent: routines[i].id == home.currentRoutine?.id,
            timingHint: routines[i].id == home.currentRoutine?.id
                ? home.currentRoutineCard?.timingHint
                : null,
            isFirst: i == 0,
            isLast: i == routines.length - 1,
            onTap: () => onOpen(routines[i]),
          ),
      ],
    );
  }
}

/// 상태 → 배지. 홈 첫 카드·위젯과 같은 말과 색을 쓴다.
(String, AppStatusBadgeTone) routineStatusBadge(
  AppLocalizations l10n,
  RoutineLogStatus status,
) =>
    switch (status) {
      RoutineLogStatus.active => (
          l10n.statusInProgress,
          AppStatusBadgeTone.info
        ),
      RoutineLogStatus.snoozed => (
          l10n.statusSnoozedShort,
          AppStatusBadgeTone.meta
        ),
      RoutineLogStatus.completed => (
          l10n.statusCompleted,
          AppStatusBadgeTone.success
        ),
      RoutineLogStatus.skipped => (
          l10n.statusSkippedShort,
          AppStatusBadgeTone.neutral
        ),
      RoutineLogStatus.expired || RoutineLogStatus.noResponse => (
          l10n.statusMissed,
          AppStatusBadgeTone.readySoon
        ),
      RoutineLogStatus.scheduled => (
          l10n.statusUpcoming,
          AppStatusBadgeTone.warning
        ),
    };

class _Summary extends StatelessWidget {
  const _Summary({required this.routines, required this.statuses});

  final List<Routine> routines;
  final List<RoutineLogStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final done = statuses.where((s) => s == RoutineLogStatus.completed).length;
    return Semantics(
      label: '${l10n.statusCompleted} $done / ${routines.length}',
      excludeSemantics: true,
      child: Row(
        key: const Key('routines-today-summary'),
        children: [
          PixelDigits('$done/${routines.length}', height: 18),
          const SizedBox(width: 6),
          Text(l10n.statusCompleted, style: AppTextStyles.caption),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 10,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < routines.length; i++) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          // 완료한 칸만 루틴 색으로 채운다 — 원판의 색 호와 같다.
                          color: statuses[i] == RoutineLogStatus.completed
                              ? routines[i].color
                              : AppColors.orbitSurface,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.routine,
    required this.status,
    required this.isCurrent,
    required this.timingHint,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final Routine routine;
  final RoutineLogStatus status;
  final bool isCurrent;
  final String? timingHint;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  static const _timeWidth = 44.0;
  static const _railWidth = 22.0;

  /// 카드 아래 간격. 레일은 이 간격까지 이어 그리고, 점과 시각은 카드 가운데에 둔다.
  static const _gap = 10.0;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _timeWidth,
            child: Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Center(
                // 큰 글꼴에서 시각이 두 줄로 접히지 않게 칸 안으로 줄인다.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    TimeMinutes.formatHm(routine.startMinutesFromMidnight),
                    style: AppTextStyles.captionTight.copyWith(
                      color: isCurrent ? primary : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: _railWidth,
            child: CustomPaint(
              painter: _RailPainter(
                color: AppColors.decorationOutline,
                drawTop: !isFirst,
                drawBottom: !isLast,
                bottomGap: _gap,
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: _gap),
                child: Center(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: routine.color,
                      border:
                          Border.all(color: AppColors.textPrimary, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: _TimelineCard(
                routine: routine,
                status: status,
                isCurrent: isCurrent,
                timingHint: timingHint,
                onTap: onTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({
    required this.routine,
    required this.status,
    required this.isCurrent,
    required this.timingHint,
    required this.onTap,
  });

  final Routine routine;
  final RoutineLogStatus status;
  final bool isCurrent;
  final String? timingHint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).colorScheme.primary;
    final (label, tone) = routineStatusBadge(l10n, status);
    final done = status == RoutineLogStatus.completed;
    final faded = status == RoutineLogStatus.skipped ||
        status == RoutineLogStatus.expired ||
        status == RoutineLogStatus.noResponse;
    final shape = AppPixelStyle.shape();
    // 언어마다 배지 길이가 크게 다르다(«예정» / «Upcoming»). 이름보다 넓어지지
    // 않게 상한을 두면 넘칠 때 배지 글자가 말줄임된다.
    final badge = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 96),
      child: AppStatusBadge(label: label, tone: tone, compact: isCurrent),
    );
    final range = TimeMinutes.formatRange(
      routine.startMinutesFromMidnight,
      routine.endMinutesFromMidnight,
    );

    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: ShapeDecoration(
          color: isCurrent
              ? null
              : done || faded
                  ? AppColors.decorationCream
                  : AppColors.orbitSurface,
          gradient:
              isCurrent ? context.appTheme.preset.focusCardGradient : null,
          shape: shape,
          shadows: const [
            BoxShadow(
              color: AppPixelStyle.shadow,
              offset: AppPixelStyle.cardOffset,
            ),
          ],
        ),
        child: InkWell(
          key: Key('routines-today-${routine.id}'),
          customBorder: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: isCurrent ? 64 : 54),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Row(
                children: [
                  Opacity(
                    opacity: faded ? 0.55 : 1,
                    child: RoutineMark(
                      icon: routine.iconId,
                      color: routine.color,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                routine.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  fontSize: 15,
                                  // 끝난 루틴은 차분하게 — 취소선은 쓰지 않는다.
                                  color: done || faded
                                      ? AppColors.textMuted
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isCurrent) ...[
                              const SizedBox(width: 6),
                              Flexible(child: badge),
                            ],
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isCurrent && timingHint != null ? timingHint! : range,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: isCurrent
                              ? AppTextStyles.captionTight.copyWith(
                                  color: primary,
                                  fontWeight: FontWeight.w700,
                                )
                              : AppTextStyles.captionTight,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCurrent)
                    SizedBox(
                      key: Key('routines-today-cat-${routine.id}'),
                      width: 52,
                      height: 52,
                      child: AnimatedCat(
                        pose:
                            catPoseFor(status: status, iconId: routine.iconId),
                      ),
                    )
                  else if (done)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: AppColors.successText,
                        ),
                        const SizedBox(width: 2),
                        badge,
                      ],
                    )
                  else
                    badge,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 레일 — 점 사이를 잇는 점선. 첫 항목은 위, 마지막 항목은 아래를 비운다.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.drawTop,
    required this.drawBottom,
    required this.bottomGap,
  });

  final Color color;
  final bool drawTop;
  final bool drawBottom;
  final double bottomGap;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    final x = (size.width / 2).floorToDouble() - 1;
    final mid = (size.height - bottomGap) / 2;
    final top = drawTop ? 0.0 : mid;
    final bottom = drawBottom ? size.height : mid;
    for (var y = top; y < bottom; y += 6) {
      canvas.drawRect(Rect.fromLTWH(x, y, 2, 3), paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.color != color ||
      old.drawTop != drawTop ||
      old.drawBottom != drawBottom ||
      old.bottomGap != bottomGap;
}
