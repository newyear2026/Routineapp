import 'package:flutter/material.dart';

import '../../domain/models/routine.dart';
import '../../domain/models/routine_log_status.dart';
import '../../models/home_models.dart';
import 'progress_summary.dart';

/// Home 화면에 필요한 데이터를 한 번에 묶은 스냅샷 (ViewModel 역할).
///
/// 계산은 [HomeSnapshotBuilder] — 화면/위젯은 이 타입만 소비한다.
typedef HomeViewModel = HomeSnapshot;

class HomeSnapshot {
  const HomeSnapshot({
    required this.dateLabel,
    required this.dayOfWeekLabel,
    required this.dateWithWeekdayLabel,
    required this.greeting,
    required this.todayRoutines,
    required this.currentRoutine,
    required this.nextRoutine,
    required this.displayRoutine,
    required this.nextAfterDisplay,
    required this.upcomingRoutines,
    required this.dayProgressPercent,
    required this.completedCount,
    required this.totalCount,
    required this.currentRoutineLogStatus,
    this.currentRoutineStatusLabel,
    required this.clockTime,
    required this.centerRoutineName,
    required this.segments,
    required this.activeRoutineForRing,
    required this.currentRoutineCard,
    required this.nextRoutineCard,
    required this.character,
    required this.isDisplayUpcoming,
    required this.completeButtonLabel,
    required this.canActOnCurrentSlot,
    this.actionDisabledMessage,
    required this.homeProgress,
    required this.progressSummary,
    required this.isEmptyDay,
  });

  // —— 헤더 ——
  final String dateLabel;
  final String dayOfWeekLabel;

  /// 홈 헤더용 — 날짜와 요일을 로케일 어순으로 합친 한 줄.
  final String dateWithWeekdayLabel;
  final String greeting;

  // —— 도메인 지표 (요청 필드) ——
  final List<Routine> todayRoutines;

  /// 현재 시각이 속한 루틴 시간대 (없으면 null)
  final Routine? currentRoutine;

  /// 스케줄상 바로 다음 루틴 (같은 날 기준)
  final Routine? nextRoutine;

  /// 카드 중심에 쓸 루틴 (시간대 없으면 다가오는 루틴)
  final Routine? displayRoutine;
  final Routine? nextAfterDisplay;

  /// [displayRoutine] 이후 오늘 남은 루틴 전체 (시간 오름차순).
  ///
  /// Home '다음 일정' 목록은 이 값만 쓴다. [nextAfterDisplay]와 함께 그리면
  /// 첫 항목이 중복된다.
  final List<Routine> upcomingRoutines;

  /// 오늘 전체 진행 0~100 (완료/전체)
  final int dayProgressPercent;
  final int completedCount;
  final int totalCount;

  /// [calculateProgress]와 동일 값 — 위젯·확장 시 우선 사용
  final ProgressSummary progressSummary;

  /// 현재 슬롯 루틴의 **최종 표시 상태** (시간 + 로그, [RoutineStateResolver])
  final RoutineLogStatus? currentRoutineLogStatus;

  /// 카드·배너 근처에 짧게 표시할 한 줄 (null이면 미표시)
  final String? currentRoutineStatusLabel;

  /// [dayProgressPercent] 와 동일 — 요청 필드명 `progressPercent` 대응
  int get progressPercent => dayProgressPercent;

  // —— 원형 시간표 ——
  final TimeOfDay clockTime;
  final String centerRoutineName;
  final List<RoutineSegment> segments;
  final CurrentRoutine? activeRoutineForRing;

  // —— 카드 / 캐릭터 / CTA ——
  final CurrentRoutine? currentRoutineCard;
  final NextRoutine? nextRoutineCard;
  final CharacterCopy character;
  final bool isDisplayUpcoming;
  final String completeButtonLabel;
  final bool canActOnCurrentSlot;
  final String? actionDisabledMessage;
  final HomeProgress homeProgress;
  final bool isEmptyDay;
}
