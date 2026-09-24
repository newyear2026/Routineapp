import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/progress/daily_progress.dart';
import '../../domain/utils/time_minutes.dart';
import '../../l10n/app_localizations.dart';
import '../../models/progress_models.dart';

/// 도메인 [Routine]·[RoutineLog] → Progress 화면용 [ProgressStatusGroup] 등
abstract final class ProgressViewMapper {
  static List<ProgressStatusGroup> buildStatusGroups({
    required AppLocalizations l10n,
    required List<Routine> todayRoutines,
    required List<RoutineLog> logsToday,
  }) {
    if (todayRoutines.isEmpty) return [];

    final routineIds = todayRoutines.map((r) => r.id).toSet();
    final byId = {for (final r in todayRoutines) r.id: r};
    final grouped = groupLogsByStatus(
      logsToday,
      routineIdsFilter: routineIds,
    );

    int logOrder(RoutineLog a, RoutineLog b) {
      final ma = byId[a.routineId]?.startMinutesFromMidnight ?? 0;
      final mb = byId[b.routineId]?.startMinutesFromMidnight ?? 0;
      return ma.compareTo(mb);
    }

    ProgressRoutineItem itemFor(RoutineLog log) {
      final r = byId[log.routineId];
      return ProgressRoutineItem(
        emoji: r?.iconEmoji ?? '',
        name: r?.title ?? l10n.commonRoutine,
        timeLabel: TimeMinutes.formatHm(r?.startMinutesFromMidnight ?? 0),
      );
    }

    final pendingLogs = [...grouped.other]..sort(logOrder);
    final noResponseLogs = [...grouped.noResponse]..sort(logOrder);

    final out = <ProgressStatusGroup>[];
    if (grouped.completed.isNotEmpty) {
      final sorted = [...grouped.completed]..sort(logOrder);
      out.add(ProgressStatusGroup(
        status: ProgressRoutineStatus.completed,
        items: sorted.map(itemFor).toList(),
      ));
    }
    if (grouped.snoozed.isNotEmpty) {
      final sorted = [...grouped.snoozed]..sort(logOrder);
      out.add(ProgressStatusGroup(
        status: ProgressRoutineStatus.later,
        items: sorted.map(itemFor).toList(),
      ));
    }
    if (grouped.skipped.isNotEmpty) {
      final sorted = [...grouped.skipped]..sort(logOrder);
      out.add(ProgressStatusGroup(
        status: ProgressRoutineStatus.skipped,
        items: sorted.map(itemFor).toList(),
      ));
    }
    if (noResponseLogs.isNotEmpty) {
      out.add(ProgressStatusGroup(
        status: ProgressRoutineStatus.noResponse,
        items: noResponseLogs.map(itemFor).toList(),
      ));
    }
    if (pendingLogs.isNotEmpty) {
      out.add(ProgressStatusGroup(
        status: ProgressRoutineStatus.pending,
        items: pendingLogs.map(itemFor).toList(),
      ));
    }
    return out;
  }

  static ProgressFeedbackContent feedbackForPercent(
    AppLocalizations l10n,
    int percent,
  ) {
    if (percent >= 100) {
      return ProgressFeedbackContent(
        titleEmoji: '🎉',
        title: l10n.progressHeroAllDoneTitle,
        message: l10n.progressHeroAllDoneBody,
        subMessage: l10n.progressHeroAllDoneFoot,
      );
    }
    if (percent >= 50) {
      return ProgressFeedbackContent(
        titleEmoji: '💪',
        title: l10n.progressHeroHalfTitle,
        message: l10n.progressHeroHalfBody,
        subMessage: l10n.progressHeroHalfFoot,
      );
    }
    return ProgressFeedbackContent(
      titleEmoji: '✨',
      title: l10n.progressHeroStartTitle,
      message: l10n.progressHeroStartBody,
      subMessage: l10n.progressHeroStartFoot,
    );
  }

  static List<ProgressMiniStat> miniStatsFromProgress({
    required AppLocalizations l10n,
    required int completed,
    required int total,
  }) {
    return [
      ProgressMiniStat(
        emoji: '✅',
        label: l10n.progressDoneToday,
        value: total > 0 ? '$completed / $total' : '-',
      ),
      ProgressMiniStat(
        emoji: '📅',
        label: l10n.progressRemaining,
        value: total > 0
            ? l10n.routineCount((total - completed).clamp(0, total))
            : '-',
      ),
    ];
  }
}
