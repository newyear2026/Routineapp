import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/progress/daily_progress.dart';
import '../../domain/utils/time_minutes.dart';
import '../../models/progress_models.dart';

/// 도메인 [Routine]·[RoutineLog] → Progress 화면용 [ProgressStatusGroup] 등
abstract final class ProgressViewMapper {
  static List<ProgressStatusGroup> buildStatusGroups({
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
        emoji: r?.iconEmoji ?? '📌',
        name: r?.title ?? '루틴',
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

  static ProgressFeedbackContent feedbackForPercent(int percent) {
    if (percent >= 100) {
      return const ProgressFeedbackContent(
        characterEmoji: '🐻',
        titleEmoji: '🎉',
        title: '오늘 루틴 완료',
        message: '계획한 루틴을 모두 마쳤어요!',
        subMessage: '내일도 함께해요',
      );
    }
    if (percent >= 50) {
      return const ProgressFeedbackContent(
        characterEmoji: '🐻',
        titleEmoji: '💪',
        title: '절반 넘었어요',
        message: '이대로만 가면 돼요.',
        subMessage: '남은 루틴도 화이팅',
      );
    }
    return const ProgressFeedbackContent(
      characterEmoji: '🐻',
      titleEmoji: '✨',
      title: '오늘 하루',
      message: '조금씩 채워가면 돼요.',
      subMessage: '작은 완료도 큰 도움이에요',
    );
  }

  static List<ProgressMiniStat> miniStatsFromProgress({
    required int completed,
    required int total,
  }) {
    return [
      ProgressMiniStat(
        emoji: '✅',
        label: '오늘 완료',
        value: total > 0 ? '$completed / $total' : '-',
      ),
      ProgressMiniStat(
        emoji: '📅',
        label: '남은 루틴',
        value: total > 0 ? '${(total - completed).clamp(0, total)}개' : '-',
      ),
    ];
  }
}
