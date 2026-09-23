import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../domain/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../widgets/routine_load_failure_view.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_log_status.dart';
import '../domain/progress/daily_progress.dart';
import '../domain/utils/time_minutes.dart';
import '../domain/services/routine_state_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

/// 현재 루틴을 먼저 보여주고, 오늘 요약과 나머지 상태를 이어서 보여준다.
class TodayProgressScreen extends StatelessWidget {
  const TodayProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        final l10n = AppLocalizations.of(context);
        if (app.hasBlockingLoadError) {
          return const Scaffold(body: RoutineLoadFailureView());
        }
        if (!app.isLoaded) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.orbitPrimary),
            ),
          );
        }

        final now = app.now;
        final routines = app.todayScheduledRoutines;
        final progress = calculateProgress(routines, app.todayLogs);
        final groups = _buildProgressGroups(
          l10n: l10n,
          routines: routines,
          logs: app.todayLogs,
          now: now,
        );
        final activeGroup = groups.firstWhere(
          (group) => group.kind == _ProgressKind.active,
        );

        return Scaffold(
          bottomNavigationBar: OrbitBottomNavigation(
            currentIndex: 1,
            onHome: () => context.go('/home'),
            onProgress: () {},
            onRoutines: () => context.go('/routines'),
            onSettings: () => context.go('/settings'),
          ),
          body: AppScreenShell(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProgressHeader(
                    title: l10n.progressTitle,
                    subtitle: l10n.progressSubtitle,
                  ),
                  const SizedBox(height: 20),
                  if (activeGroup.items.isNotEmpty)
                    _ProgressGroup(
                      key: const Key('progress-active-group'),
                      group: activeGroup,
                    ),
                  _ProgressHero(
                    completed: progress.completed,
                    total: progress.total,
                    percent: progress.percent,
                  ),
                  const SizedBox(height: 22),
                  ...groups
                      .where((g) =>
                          (g.kind != _ProgressKind.active || g.items.isEmpty) &&
                          !(g.hideWhenEmpty && g.items.isEmpty))
                      .map((group) => _ProgressGroup(group: group)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 300 ||
              MediaQuery.textScalerOf(context).scale(16) > 20;
          final catSize = compact ? 88.0 : 120.0;
          return SizedBox(
            key: const Key('progress-header'),
            child: Stack(
              children: [
                Positioned(
                  key: const Key('progress-sky-decoration'),
                  right: -8,
                  bottom: -3,
                  child: IgnorePointer(
                    child: Image.asset(
                      'assets/decorations/progress-sky.png',
                      width: compact ? 160 : 200,
                      height: compact ? 100 : 125,
                      filterQuality: FilterQuality.none,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: AppTextStyles.titleScreen.copyWith(
                                fontSize: compact ? 22 : 28,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(subtitle, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox.square(
                      key: const Key('progress-menu-cat'),
                      dimension: catSize,
                      child: const AnimatedCat(pose: CatPose.complete),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}

class _ProgressHero extends StatelessWidget {
  const _ProgressHero({
    required this.completed,
    required this.total,
    required this.percent,
  });

  final int completed;
  final int total;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('progress-summary'),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: appSurfaceDecoration(radius: 24, elevated: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).commonToday,
                    style: AppTextStyles.bodyStrong,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$completed / $total',
                    maxLines: 1,
                    style: AppTextStyles.statMedium.copyWith(fontSize: 28),
                  ),
                  if (total > 0) ...[
                    const Text(' · ', style: AppTextStyles.statMedium),
                    Text(
                      '$percent%',
                      style: AppTextStyles.statMedium.copyWith(fontSize: 28),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (total > 0) ...[
            const SizedBox(height: 12),
            _ProgressBar(percent: percent, total: total),
            const SizedBox(height: 12),
          ],
          Text(
              _progressMessage(
                l10n: AppLocalizations.of(context),
                completed: completed,
                total: total,
                percent: percent,
              ),
              style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// 오늘 얼마나 왔는지를 형태로 보여주는 막대.
///
/// 0%에서도 트랙이 남아 '채워질 자리'로 읽힌다. 원형 게이지는 0%일 때
/// 아무것도 그려지지 않아 장식처럼 보였다.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.percent, required this.total});

  final int percent;
  final int total;

  @override
  Widget build(BuildContext context) => SegmentedProgress(
        value: percent / 100,
        segmentCount: total.clamp(1, 12),
        semanticLabel: AppLocalizations.of(context).progressSemantic(percent),
      );
}

/// 0%에 '좋은 흐름이에요'가 뜨면 상태를 잘못 말하는 문구가 된다.
///
/// 도넛을 걷어내며 카드 폭을 다 쓸 수 있게 됐지만, 한 줄은 유지한다.
/// 두 줄이 되면 아래 막대와 붙어 카드가 답답해진다.
String _progressMessage({
  required AppLocalizations l10n,
  required int completed,
  required int total,
  required int percent,
}) {
  if (total == 0) return l10n.progressNoRoutines;
  if (completed == 0) return l10n.progressNotStarted;
  if (percent >= 100) return l10n.progressAllDone;
  if (percent >= 70) return l10n.progressGreatFlow;
  return l10n.progressGoodFlow;
}

enum _ProgressKind { completed, active, upcoming, other }

class _ProgressGroupData {
  const _ProgressGroupData({
    required this.title,
    required this.emptyMessage,
    required this.tint,
    required this.textColor,
    required this.icon,
    required this.items,
    required this.kind,
    this.hideWhenEmpty = false,
  });

  final _ProgressKind kind;

  final String title;
  final String emptyMessage;

  /// 평소에는 없는 상태(건너뜀·놓침)는 비어 있으면 아예 그리지 않는다.
  /// 빈 줄을 항상 남기면 화면만 길어진다.
  final bool hideWhenEmpty;

  /// 아이콘 칩 배경 등 장식용 (대비 기준 밖)
  final Color tint;

  /// 라벨·아이콘용 — 흰 서피스 위 4.5:1 이상
  final Color textColor;
  final IconData icon;
  final List<Routine> items;
}

List<_ProgressGroupData> _buildProgressGroups({
  required AppLocalizations l10n,
  required List<Routine> routines,
  required List<RoutineLog> logs,
  required DateTime now,
}) {
  final logByRoutineId = {for (final log in logs) log.routineId: log};
  final completed = <Routine>[];
  final active = <Routine>[];
  final scheduled = <Routine>[];
  final skipped = <Routine>[];
  final missed = <Routine>[];

  for (final routine in routines) {
    final state = RoutineStateResolver.effectiveStatus(
      routine: routine,
      log: logByRoutineId[routine.id],
      nowLocal: now,
    );
    switch (state) {
      case RoutineLogStatus.completed:
        completed.add(routine);
        break;
      case RoutineLogStatus.active:
      case RoutineLogStatus.snoozed:
        active.add(routine);
        break;
      case RoutineLogStatus.scheduled:
        scheduled.add(routine);
        break;
      // 아래 두 갈래를 버리면 진행률 분모(오늘 루틴 전체)에는 남아 있는
      // 루틴이 목록에서만 사라진다. '2 / 5'인데 네 줄만 보이게 된다.
      case RoutineLogStatus.skipped:
        skipped.add(routine);
        break;
      case RoutineLogStatus.expired:
      case RoutineLogStatus.noResponse:
        missed.add(routine);
        break;
    }
  }

  int byTime(Routine a, Routine b) =>
      a.startMinutesFromMidnight.compareTo(b.startMinutesFromMidnight);
  completed.sort(byTime);
  active.sort(byTime);
  scheduled.sort(byTime);
  skipped.sort(byTime);
  missed.sort(byTime);

  return [
    _ProgressGroupData(
      title: l10n.progressGroupCompleted,
      emptyMessage: l10n.progressGroupCompletedEmpty,
      tint: AppColors.success,
      textColor: AppColors.successText,
      icon: Icons.check_rounded,
      items: completed,
      kind: _ProgressKind.completed,
    ),
    _ProgressGroupData(
      title: l10n.progressGroupActive,
      emptyMessage: l10n.progressGroupActiveEmpty,
      tint: AppColors.orbitPrimary,
      textColor: AppColors.activeText,
      icon: Icons.play_arrow_rounded,
      items: active,
      kind: _ProgressKind.active,
    ),
    _ProgressGroupData(
      title: l10n.progressGroupUpcoming,
      emptyMessage: l10n.progressGroupUpcomingEmpty,
      tint: AppColors.orbitAccent,
      textColor: AppColors.scheduledText,
      icon: Icons.schedule_rounded,
      items: scheduled,
      kind: _ProgressKind.upcoming,
    ),
    // 지나간 두 상태는 색으로 다그치지 않는다. 중립 회색 + 제목으로 구분한다.
    // 스킵은 사용자가 고른 결과이고 놓침은 응답이 없던 것이라 섞지 않는다.
    _ProgressGroupData(
      title: l10n.progressGroupSkipped,
      emptyMessage: l10n.progressGroupSkippedEmpty,
      tint: AppColors.textMuted,
      textColor: AppColors.textMuted,
      icon: Icons.skip_next_rounded,
      items: skipped,
      hideWhenEmpty: true,
      kind: _ProgressKind.other,
    ),
    _ProgressGroupData(
      title: l10n.progressGroupMissed,
      emptyMessage: l10n.progressGroupMissedEmpty,
      tint: AppColors.textMuted,
      textColor: AppColors.textMuted,
      icon: Icons.history_rounded,
      items: missed,
      hideWhenEmpty: true,
      kind: _ProgressKind.other,
    ),
  ];
}

class _ProgressGroup extends StatelessWidget {
  const _ProgressGroup({super.key, required this.group});

  final _ProgressGroupData group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSection,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                  AppLocalizations.of(context).routineCount(group.items.length),
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 10),
          if (group.items.isEmpty)
            _GroupEmpty(message: group.emptyMessage)
          else
            ...group.items.indexed.map(
              (entry) => Padding(
                padding: EdgeInsets.only(
                  bottom: entry.$1 == group.items.length - 1 ? 0 : 8,
                ),
                child: AppRoutineRow(
                  color: entry.$2.color,
                  icon: entry.$2.iconId,
                  title: entry.$2.title,
                  subtitle: TimeMinutes.formatRange(
                    entry.$2.startMinutesFromMidnight,
                    entry.$2.endMinutesFromMidnight,
                  ),
                  trailing: _RoutineStatusTrailing(
                    kind: group.kind,
                    label: group.title,
                    tint: group.tint,
                    textColor: group.textColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupEmpty extends StatelessWidget {
  const _GroupEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: Alignment.centerLeft,
      // orbitSurfaceSoft는 페이지 배경과 1.08:1이라 상자가 보이지 않는다.
      // 같은 화면의 루틴 행과 동일한 흰 서피스를 쓴다.
      decoration: appSurfaceDecoration(radius: 16),
      child: Text(message, style: AppTextStyles.caption),
    );
  }
}

class _RoutineStatusTrailing extends StatelessWidget {
  const _RoutineStatusTrailing({
    required this.kind,
    required this.label,
    required this.tint,
    required this.textColor,
  });

  final _ProgressKind kind;
  final String label;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case _ProgressKind.completed:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.orbitPrimary.withValues(alpha: 0.16),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: AppIcon(Icons.check_rounded,
                size: 16, color: AppColors.orbitPrimary),
          ),
        );
      case _ProgressKind.active:
        return AppStatusBadge(
          label: AppLocalizations.of(context).statusInProgress,
          tone: AppStatusBadgeTone.info,
        );
      case _ProgressKind.upcoming:
        return const AppIcon(
          Icons.chevron_right_rounded,
          color: AppColors.textMuted,
        );
      case _ProgressKind.other:
        return AppStatusBadge(label: label, tone: AppStatusBadgeTone.neutral);
    }
  }
}
