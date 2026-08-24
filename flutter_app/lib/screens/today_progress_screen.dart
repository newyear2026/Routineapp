import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../domain/models/routine.dart';
import '../l10n/app_localizations.dart';
import '../domain/models/routine_log.dart';
import '../domain/models/routine_log_status.dart';
import '../domain/progress/daily_progress.dart';
import '../domain/utils/app_date_formats.dart';
import '../domain/utils/time_minutes.dart';
import '../domain/services/routine_state_resolver.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

/// Figma 기준 진행 화면: 완료 · 진행 중 · 예정의 세 상태를 항상 보여준다.
class TodayProgressScreen extends StatelessWidget {
  const TodayProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        final l10n = AppLocalizations.of(context);
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
                  Text(l10n.progressTitle, style: AppTextStyles.titleScreen),
                  const SizedBox(height: 3),
                  Text(AppDateFormats.monthDay(context, now),
                      style: AppTextStyles.caption),
                  const SizedBox(height: 24),
                  _ProgressHero(
                    completed: progress.completed,
                    total: progress.total,
                    percent: progress.percent,
                  ),
                  const SizedBox(height: 28),
                  ...groups
                      .where((g) => !(g.hideWhenEmpty && g.items.isEmpty))
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: appSurfaceDecoration(radius: 24, elevated: true),
      // 진행률은 '$completed / $total' 하나로만 말한다.
      //
      // 예전에는 옆에 도넛을 두고 그 안에 '$percent%'를 또 적었다. 같은 사실을
      // 두 번 말하는 데다(UI_STANDARDS 7), 0%에서는 호가 그려지지 않아 카드
      // 오른쪽 절반이 비어 보였다 — 앱을 여는 아침마다 보게 되는 상태다.
      //
      // 원은 이 앱에서 '하루 24시간'을 뜻한다(홈 시간표·홈 위젯).
      // 비율까지 원으로 그리면 같은 형태가 두 가지 뜻을 갖는다.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$completed / $total', style: AppTextStyles.statHero),
          const SizedBox(height: 8),
          Text(
            _progressMessage(
              l10n: AppLocalizations.of(context),
              completed: completed,
              total: total,
              percent: percent,
            ),
            style: AppTextStyles.titleSection.copyWith(
              color: AppColors.orbitPrimary,
            ),
          ),
          // 오늘 루틴이 없으면 채울 것도 없다. 빈 막대를 남기지 않는다.
          if (total > 0) ...[
            const SizedBox(height: 16),
            _ProgressBar(percent: percent),
          ],
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
  const _ProgressBar({required this.percent});

  final int percent;

  static const double _height = 8;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppLocalizations.of(context).progressSemantic(percent),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          height: _height,
          child: Stack(
            children: [
              const ColoredBox(
                color: AppColors.orbitHalo,
                child: SizedBox.expand(),
              ),
              FractionallySizedBox(
                widthFactor: (percent / 100).clamp(0.0, 1.0),
                child: const ColoredBox(
                  color: AppColors.orbitPrimary,
                  child: SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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

class _ProgressGroupData {
  const _ProgressGroupData({
    required this.title,
    required this.emptyMessage,
    required this.tint,
    required this.textColor,
    required this.icon,
    required this.items,
    this.hideWhenEmpty = false,
  });

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
    ),
    _ProgressGroupData(
      title: l10n.progressGroupActive,
      emptyMessage: l10n.progressGroupActiveEmpty,
      tint: AppColors.orbitPrimary,
      textColor: AppColors.activeText,
      icon: Icons.play_arrow_rounded,
      items: active,
    ),
    _ProgressGroupData(
      title: l10n.progressGroupUpcoming,
      emptyMessage: l10n.progressGroupUpcomingEmpty,
      tint: AppColors.orbitAccent,
      textColor: AppColors.scheduledText,
      icon: Icons.schedule_rounded,
      items: scheduled,
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
    ),
    _ProgressGroupData(
      title: l10n.progressGroupMissed,
      emptyMessage: l10n.progressGroupMissedEmpty,
      tint: AppColors.textMuted,
      textColor: AppColors.textMuted,
      icon: Icons.history_rounded,
      items: missed,
      hideWhenEmpty: true,
    ),
  ];
}

class _ProgressGroup extends StatelessWidget {
  const _ProgressGroup({required this.group});

  final _ProgressGroupData group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: group.tint.withValues(alpha: .18),
                  shape: BoxShape.circle,
                ),
                child: Icon(group.icon, color: group.textColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(group.title, style: AppTextStyles.titleSection),
              const SizedBox(width: 8),
              // 홈·루틴 화면과 같은 단위를 쓴다. 여기만 숫자만 적으면 어긋난다.
              Text(AppLocalizations.of(context).routineCount(group.items.length),
                  style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 12),
          if (group.items.isEmpty)
            _GroupEmpty(message: group.emptyMessage)
          else
            ...group.items.map(
              (routine) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppRoutineRow(
                  color: routine.color,
                  title: routine.title,
                  trailing: _RoutineStatusTrailing(
                    time: TimeMinutes.formatHm(
                      routine.startMinutesFromMidnight,
                    ),
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
    required this.time,
    required this.label,
    required this.tint,
    required this.textColor,
  });

  final String time;
  final String label;
  final Color tint;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: AppTextStyles.caption),
        const SizedBox(width: 10),
        // 색만으로 구분하지 않도록 배지 형태 + 문구를 함께 쓴다.
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: .18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
