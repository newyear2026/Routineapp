import 'package:flutter/material.dart';

import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/progress/daily_progress.dart';
import '../../domain/services/home_routine_schedule.dart';
import '../../domain/services/routine_day_service.dart';
import '../../domain/services/routine_progress_service.dart';
import '../../domain/services/routine_state_resolver.dart';
import '../../domain/utils/app_date_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/home_models.dart';
import '../mappers/home_view_mapper.dart';
import 'home_focus_state.dart';
import 'home_snapshot.dart';
import 'progress_summary.dart';

/// Home 스냅샷 조립 — 로컬/더미 저장소에서 읽은 [Routine]·[RoutineLog]만 넘기면 됨
abstract final class HomeSnapshotBuilder {
  static HomeSnapshot build({
    required AppLocalizations l10n,
    required DateTime nowLocal,
    required List<Routine> allRoutines,
    required List<RoutineLog> logsToday,
    RoutineDayService dayService = const RoutineDayService(),
    RoutineProgressService progressService = const RoutineProgressService(),
  }) {
    final localeName = l10n.localeName;
    final dateLabel = AppDateFormats.monthDayIn(localeName, nowLocal);
    final dayOfWeekLabel = AppDateFormats.weekdayFullIn(localeName, nowLocal);
    final dateWithWeekdayLabel =
        AppDateFormats.monthDayWeekdayIn(localeName, nowLocal);
    final greeting = _greetingForHour(l10n, nowLocal.hour);

    final todaySorted =
        HomeRoutineSchedule.getTodayRoutines(nowLocal, allRoutines);
    final current =
        HomeRoutineSchedule.getCurrentRoutine(nowLocal, todaySorted);
    final next = HomeRoutineSchedule.getNextRoutine(nowLocal, todaySorted);

    final display = current ?? next;
    final upcomingRoutines = display != null
        ? HomeRoutineSchedule.routinesAfter(display, todaySorted)
        : const <Routine>[];
    final nextAfterDisplay =
        upcomingRoutines.isEmpty ? null : upcomingRoutines.first;

    // Home 상단·Progress 화면과 동일: [calculateProgress] (DailyProgressCalculator)
    final dayProgress = calculateProgress(todaySorted, logsToday);
    final total = dayProgress.total;
    final completed = dayProgress.completed;
    final dayPct = dayProgress.percent;

    RoutineLogStatus? effectiveCurrent;
    if (current != null) {
      final log = dayService.logForRoutine(current.id, logsToday);
      effectiveCurrent = RoutineStateResolver.effectiveStatus(
        routine: current,
        log: log,
        nowLocal: nowLocal,
      );
    }
    final statusLabel = _statusLabel(l10n, effectiveCurrent);

    final clockTime = TimeOfDay.fromDateTime(nowLocal);
    final segments = HomeViewMapper.toSegments(todaySorted);
    final centerName = current?.title ?? next?.title ?? l10n.commonRoutine;

    final activeRing =
        current != null
            ? HomeViewMapper.ringStubFromRoutine(current, localeName)
            : null;
    final isUpcoming = current == null && display != null;

    CurrentRoutine? card;
    NextRoutine? nextCard;
    CharacterCopy character;
    if (display != null) {
      final windowPct = current != null && current.id == display.id
          ? progressService.progressPercentInWindow(display, nowLocal)
          : 0;
      card = HomeViewMapper.toCurrentRoutine(
        display,
        windowPct,
        _timingHint(
          l10n: l10n,
          nowLocal: nowLocal,
          display: display,
          isUpcoming: isUpcoming,
        ),
        localeName,
      );
      nextCard = HomeViewMapper.toNextRoutine(nextAfterDisplay);
      character = HomeViewMapper.characterFor(display);
    } else {
      card = null;
      nextCard = null;
      character = CharacterCopy(
        emoji: '🐻',
        highlightEmoji: '✨',
        highlightRoutineName: l10n.commonRoutine,
      );
    }

    final canAct = current != null &&
        RoutineStateResolver.canApplyUserAction(
          routine: current,
          log: dayService.logForRoutine(current.id, logsToday),
          nowLocal: nowLocal,
        );
    final completeLabel = _completeLabel(l10n, display);
    final focusState = HomeFocusState.resolve(
      hasRoutinesToday: todaySorted.isNotEmpty,
      hasCurrent: current != null,
      hasNext: next != null,
      currentStatus: effectiveCurrent,
    );
    final snoozedUntilMs = focusState == HomeFocusState.snoozed
        ? dayService.logForRoutine(current!.id, logsToday)?.snoozedUntilMs
        : null;
    final tomorrow = HomeRoutineSchedule.getTodayRoutines(
      DateTime(nowLocal.year, nowLocal.month, nowLocal.day + 1),
      allRoutines,
    );

    return HomeSnapshot(
      dateLabel: dateLabel,
      dayOfWeekLabel: dayOfWeekLabel,
      dateWithWeekdayLabel: dateWithWeekdayLabel,
      greeting: greeting,
      todayRoutines: List<Routine>.unmodifiable(todaySorted),
      currentRoutine: current,
      nextRoutine: next,
      displayRoutine: display,
      nextAfterDisplay: nextAfterDisplay,
      upcomingRoutines: upcomingRoutines,
      dayProgressPercent: dayPct,
      completedCount: completed,
      totalCount: total,
      currentRoutineLogStatus: effectiveCurrent,
      currentRoutineStatusLabel: statusLabel,
      clockTime: clockTime,
      centerRoutineName: centerName,
      segments: segments,
      activeRoutineForRing: activeRing,
      currentRoutineCard: card,
      nextRoutineCard: nextCard,
      character: character,
      isDisplayUpcoming: isUpcoming,
      completeButtonLabel: completeLabel,
      canActOnCurrentSlot: canAct,
      focusState: focusState,
      snoozedUntil: snoozedUntilMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(snoozedUntilMs),
      dayResult: _dayResult(
        todaySorted: todaySorted,
        logsToday: logsToday,
        nowLocal: nowLocal,
        dayService: dayService,
      ),
      tomorrowFirstRoutine: tomorrow.isEmpty ? null : tomorrow.first,
      homeProgress: HomeProgress(completed: completed, total: total),
      progressSummary: ProgressSummary.fromResult(dayProgress),
      isEmptyDay: todaySorted.isEmpty,
    );
  }

  static String _greetingForHour(AppLocalizations l10n, int hour) {
    if (hour < 12) return l10n.greetingMorning;
    if (hour < 18) return l10n.greetingAfternoon;
    return l10n.greetingEvening;
  }

  /// 버튼 라벨은 **항상 할 일**을 말한다.
  ///
  /// 누를 수 없는 상태에서는 버튼 자체를 숨긴다 ([HomeFocusState.showsSlotActions]).
  static String _completeLabel(AppLocalizations l10n, Routine? display) {
    if (display == null) return l10n.actionComplete;
    return l10n.actionCompleteNamed(display.title);
  }

  static String? _statusLabel(AppLocalizations l10n, RoutineLogStatus? s) {
    if (s == null) return null;
    switch (s) {
      case RoutineLogStatus.scheduled:
      case RoutineLogStatus.active:
        return null;
      case RoutineLogStatus.completed:
        return l10n.slotAlreadyCompleted;
      case RoutineLogStatus.snoozed:
        return l10n.slotSnoozedNotice;
      case RoutineLogStatus.skipped:
        return l10n.slotSkippedNotice;
      case RoutineLogStatus.noResponse:
        return l10n.statusNoResponse;
      case RoutineLogStatus.expired:
        return l10n.slotExpiredNotice;
    }
  }

  static HomeDayResult _dayResult({
    required List<Routine> todaySorted,
    required List<RoutineLog> logsToday,
    required DateTime nowLocal,
    required RoutineDayService dayService,
  }) {
    var completed = 0;
    var skipped = 0;
    var missed = 0;
    for (final routine in todaySorted) {
      final status = RoutineStateResolver.effectiveStatus(
        routine: routine,
        log: dayService.logForRoutine(routine.id, logsToday),
        nowLocal: nowLocal,
      );
      switch (status) {
        case RoutineLogStatus.completed:
          completed++;
        case RoutineLogStatus.skipped:
          skipped++;
        case RoutineLogStatus.expired:
        case RoutineLogStatus.noResponse:
          missed++;
        case RoutineLogStatus.scheduled:
        case RoutineLogStatus.active:
        case RoutineLogStatus.snoozed:
          break;
      }
    }
    return HomeDayResult(
      completed: completed,
      skipped: skipped,
      missed: missed,
    );
  }

  static String _timingHint({
    required AppLocalizations l10n,
    required DateTime nowLocal,
    required Routine display,
    required bool isUpcoming,
  }) {
    final nowMinutes = nowLocal.hour * 60 + nowLocal.minute;
    final targetMinutes = isUpcoming
        ? display.startMinutesFromMidnight - nowMinutes
        : display.endMinutesFromMidnight - nowMinutes;
    final safeMinutes = targetMinutes.clamp(0, 24 * 60);
    if (safeMinutes <= 0) {
      return isUpcoming ? l10n.timingStartingSoon : l10n.timingEndingNow;
    }
    final label = _durationLabel(l10n, safeMinutes);
    return isUpcoming
        ? l10n.timingUntilStart(label)
        : l10n.timingUntilEnd(label);
  }

  static String _durationLabel(AppLocalizations l10n, int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h > 0 && m > 0) return l10n.durationHoursMinutes(h, m);
    if (h > 0) return l10n.durationHours(h);
    return l10n.durationMinutes(m);
  }
}
