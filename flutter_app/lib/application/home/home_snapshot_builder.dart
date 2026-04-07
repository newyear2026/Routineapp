import 'package:flutter/material.dart';

import '../../domain/models/routine.dart';
import '../../domain/models/routine_log.dart';
import '../../domain/models/routine_log_status.dart';
import '../../domain/progress/daily_progress.dart';
import '../../domain/services/home_routine_schedule.dart';
import '../../domain/services/routine_day_service.dart';
import '../../domain/services/routine_progress_service.dart';
import '../../domain/services/routine_state_resolver.dart';
import '../../models/home_models.dart';
import '../mappers/home_view_mapper.dart';
import 'home_snapshot.dart';
import 'progress_summary.dart';

/// Home 스냅샷 조립 — 로컬/더미 저장소에서 읽은 [Routine]·[RoutineLog]만 넘기면 됨
abstract final class HomeSnapshotBuilder {
  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  static HomeSnapshot build({
    required DateTime nowLocal,
    required List<Routine> allRoutines,
    required List<RoutineLog> logsToday,
    RoutineDayService dayService = const RoutineDayService(),
    RoutineProgressService progressService = const RoutineProgressService(),
  }) {
    final dateLabel = '${nowLocal.month}월 ${nowLocal.day}일';
    final dayOfWeekLabel = '${_weekdays[nowLocal.weekday - 1]}요일';
    final greeting = _greetingForHour(nowLocal.hour);

    final todaySorted =
        HomeRoutineSchedule.getTodayRoutines(nowLocal, allRoutines);
    final current =
        HomeRoutineSchedule.getCurrentRoutine(nowLocal, todaySorted);
    final next = HomeRoutineSchedule.getNextRoutine(nowLocal, todaySorted);

    final display = current ?? next;
    final nextAfterDisplay = display != null
        ? HomeRoutineSchedule.routineAfter(display, todaySorted)
        : null;

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
    final statusLabel = _statusLabel(effectiveCurrent);

    final clockTime = TimeOfDay.fromDateTime(nowLocal);
    final segments = HomeViewMapper.toSegments(todaySorted);
    final centerName =
        current != null ? current.title : (next != null ? next.title : '루틴');

    final activeRing =
        current != null ? HomeViewMapper.ringStubFromRoutine(current) : null;

    CurrentRoutine? card;
    NextRoutine? nextCard;
    CharacterCopy character;
    if (display != null) {
      final windowPct = current != null && current.id == display.id
          ? progressService.progressPercentInWindow(display, nowLocal)
          : 0;
      card = HomeViewMapper.toCurrentRoutine(display, windowPct);
      nextCard = HomeViewMapper.toNextRoutine(nextAfterDisplay);
      character = HomeViewMapper.characterFor(display);
    } else {
      card = null;
      nextCard = null;
      character = const CharacterCopy(
        emoji: '🐻',
        highlightEmoji: '✨',
        highlightRoutineName: '루틴',
      );
    }

    final isUpcoming = current == null && display != null;
    final canAct = current != null &&
        RoutineStateResolver.canApplyUserAction(
          routine: current,
          log: dayService.logForRoutine(current.id, logsToday),
          nowLocal: nowLocal,
        );
    final completeLabel = _completeLabel(
      display,
      canAct,
      current,
      effectiveCurrent,
    );
    final disabledMessage = _actionDisabledMessage(
      todaySorted: todaySorted,
      currentSlot: current,
      nextRoutine: next,
      effectiveOnCurrent: effectiveCurrent,
    );

    return HomeSnapshot(
      dateLabel: dateLabel,
      dayOfWeekLabel: dayOfWeekLabel,
      greeting: greeting,
      todayRoutines: List<Routine>.unmodifiable(todaySorted),
      currentRoutine: current,
      nextRoutine: next,
      displayRoutine: display,
      nextAfterDisplay: nextAfterDisplay,
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
      actionDisabledMessage: disabledMessage,
      homeProgress: HomeProgress(completed: completed, total: total),
      progressSummary: ProgressSummary.fromResult(dayProgress),
      isEmptyDay: todaySorted.isEmpty,
    );
  }

  static String _greetingForHour(int hour) {
    if (hour < 12) return '좋은 아침이에요';
    if (hour < 18) return '좋은 오후예요';
    return '좋은 저녁이에요';
  }

  static String _completeLabel(
    Routine? display,
    bool canAct,
    Routine? currentSlot,
    RoutineLogStatus? effectiveOnCurrent,
  ) {
    if (display == null) return '루틴 없음';
    if (!canAct) {
      if (currentSlot != null &&
          display.id == currentSlot.id &&
          effectiveOnCurrent == RoutineLogStatus.completed) {
        return '이미 완료했어요';
      }
      if (currentSlot != null &&
          display.id == currentSlot.id &&
          effectiveOnCurrent == RoutineLogStatus.skipped) {
        return '건너뛴 루틴이에요';
      }
      return '지금은 루틴 시간이 아니에요';
    }
    return '${display.title} 완료하기';
  }

  static String? _statusLabel(RoutineLogStatus? s) {
    if (s == null) return null;
    switch (s) {
      case RoutineLogStatus.scheduled:
      case RoutineLogStatus.active:
        return null;
      case RoutineLogStatus.completed:
        return '이 루틴은 오늘 완료했어요';
      case RoutineLogStatus.snoozed:
        return '나중에 알림으로 미뤘어요';
      case RoutineLogStatus.skipped:
        return '건너뛴 루틴이에요';
      case RoutineLogStatus.noResponse:
        return '응답 없음';
      case RoutineLogStatus.expired:
        return '시간이 지났어요';
    }
  }

  static String? _actionDisabledMessage({
    required List<Routine> todaySorted,
    required Routine? currentSlot,
    required Routine? nextRoutine,
    required RoutineLogStatus? effectiveOnCurrent,
  }) {
    if (currentSlot != null) {
      switch (effectiveOnCurrent) {
        case RoutineLogStatus.completed:
          return '이 슬롯은 이미 완료했어요. 다음 루틴까지 잠시 쉬어가면 됩니다.';
        case RoutineLogStatus.skipped:
          return '이 슬롯은 이미 건너뛰었어요. 다음 루틴에서 다시 이어가세요.';
        case RoutineLogStatus.snoozed:
          return '나중에로 미뤘어요. 알림이 다시 오면 바로 처리할 수 있어요.';
        case RoutineLogStatus.expired:
          return '이 루틴 시간은 지났어요. 다음 루틴부터 다시 시작하면 됩니다.';
        default:
          return null;
      }
    }

    if (todaySorted.isEmpty) {
      return '오늘 루틴이 없어요. 오른쪽 아래 + 버튼으로 하나 추가해보세요.';
    }
    if (nextRoutine != null) {
      final hour = nextRoutine.startMinutesFromMidnight ~/ 60;
      final minute = nextRoutine.startMinutesFromMidnight % 60;
      final time =
          '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
      return '${nextRoutine.title} 루틴은 $time에 시작해요.';
    }
    return '오늘 예정된 루틴을 모두 마쳤어요.';
  }
}
