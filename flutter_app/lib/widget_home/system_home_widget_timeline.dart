import '../application/home/home_snapshot_builder.dart';
import '../domain/models/routine.dart';
import '../domain/models/routine_log.dart';
import '../domain/utils/time_minutes.dart';
import '../l10n/app_localizations.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import 'system_home_widget_payload.dart';

/// 루틴 경계와 자정의 표시 상태를 앱에서 미리 계산해 네이티브 위젯에 전달한다.
/// 앱 프로세스가 중단되어도 두 플랫폼은 이 상태를 현재 시각으로 선택할 수 있다.
abstract final class SystemHomeWidgetTimeline {
  static const horizonDays = 7;

  static SystemHomeWidgetPayload build({
    required DateTime now,
    required AppLocalizations l10n,
    required List<Routine> routines,
    required List<RoutineLog> logsToday,
  }) {
    final until = DateTime(now.year, now.month, now.day + horizonDays);
    final moments = <int>{now.millisecondsSinceEpoch};

    for (var day = 0; day < horizonDays; day++) {
      final date = DateTime(now.year, now.month, now.day + day);
      if (date.isAfter(now)) moments.add(date.millisecondsSinceEpoch);
      for (final routine in routines) {
        if (!routine.repeatWeekdays.contains(date.weekday)) continue;
        for (final minute in [
          routine.startMinutesFromMidnight,
          routine.endMinutesFromMidnight,
        ]) {
          final at = DateTime(date.year, date.month, date.day, 0, minute);
          if (at.isAfter(now) && at.isBefore(until)) {
            moments.add(at.millisecondsSinceEpoch);
          }
        }
      }
    }

    final sorted = moments.toList()..sort();
    final todayYmd = TimeMinutes.dateYmd(now);
    final states = sorted.map((ms) {
      final at = DateTime.fromMillisecondsSinceEpoch(ms);
      final logs = TimeMinutes.dateYmd(at) == todayYmd
          ? logsToday
          : const <RoutineLog>[];
      final snapshot = HomeSnapshotBuilder.build(
        l10n: l10n,
        nowLocal: at,
        allRoutines: routines,
        logsToday: logs,
      );
      final vm = HomeMediumWidgetSelector.fromSnapshot(snapshot, l10n);
      final display = snapshot.displayRoutine;
      final timingTargetMinutes = display == null
          ? null
          : snapshot.isDisplayUpcoming
              ? display.startMinutesFromMidnight
              : display.endMinutesFromMidnight;
      final timingTarget =
          vm.currentRoutineTimingHint.isEmpty || timingTargetMinutes == null
              ? null
              : DateTime(at.year, at.month, at.day, 0, timingTargetMinutes)
                  .millisecondsSinceEpoch;
      return SystemWidgetStatePayload(
        effectiveAtEpochMs: ms,
        currentRoutineTitle: vm.currentRoutineTitle,
        currentRoutineStatus: vm.currentRoutineStatusLabel,
        currentRoutineTimingHint: vm.currentRoutineTimingHint,
        nextRoutineTitle: vm.nextRoutineTitle,
        nextRoutineTime: vm.nextRoutineTime,
        centerTimeLabel: vm.centerTimeLabel,
        ringSegments:
            vm.ringSegments.map(SystemRingSegmentPayload.fromMedium).toList(),
        activeSegmentId: vm.activeSegmentId,
        timingTargetEpochMs: timingTarget,
        timingMode: timingTarget == null
            ? null
            : snapshot.isDisplayUpcoming
                ? 'start'
                : 'end',
        currentRoutineTimeRange: vm.currentRoutineTimeRange,
        upcomingRoutines:
            SystemUpcomingRoutinePayload.listFrom(snapshot.upcomingRoutines),
      );
    }).toList();

    final snapshot = HomeSnapshotBuilder.build(
      l10n: l10n,
      nowLocal: now,
      allRoutines: routines,
      logsToday: logsToday,
    );
    return SystemHomeWidgetPayload.fromHomeSnapshot(snapshot, l10n)
        .withTimeline(
      l10n: l10n,
      validUntilEpochMs: until.millisecondsSinceEpoch,
      states: states,
    );
  }
}
