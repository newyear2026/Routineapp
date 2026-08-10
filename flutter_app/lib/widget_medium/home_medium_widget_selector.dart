import '../application/home/home_snapshot.dart';
import '../domain/models/routine_log_status.dart';
import '../domain/utils/time_minutes.dart';
import '../models/home_models.dart';
import 'home_medium_widget_view_model.dart';
import 'medium_ring_segment.dart';

/// [HomeSnapshot]·도메인 지표 → Medium 위젯 [HomeMediumWidgetViewModel].
///
/// 위젯 확장·iOS WidgetKit 브리지 시 동일 selector를 재사용할 수 있도록 분리.
abstract final class HomeMediumWidgetSelector {
  /// [HomeSnapshot]이 이미 [currentRoutine]·[segments]·[clockTime] 등을 포함.
  static HomeMediumWidgetViewModel fromSnapshot(HomeSnapshot h) {
    final display = h.displayRoutine;
    final next = h.nextRoutine;

    final title = display?.title ?? '오늘 루틴이 없어요';

    final status = _statusLabel(
      logStatus: h.currentRoutineLogStatus,
      hasDisplay: display != null,
      isUpcomingOnly: h.isDisplayUpcoming,
    );

    var nextTitle = '없음';
    var nextTime = '';
    if (h.nextRoutineCard != null) {
      final n = h.nextRoutineCard!;
      nextTitle = n.name;
      nextTime = n.time;
    } else if (next != null) {
      nextTitle = next.title;
      nextTime = TimeMinutes.formatHm(next.startMinutesFromMidnight);
    }

    final ring = _ringSegmentsFromUiSegments(h.segments);
    final activeId = h.activeRoutineForRing?.id;

    return HomeMediumWidgetViewModel(
      currentRoutineTitle: title,
      // 실제로 계산된 힌트가 없으면 지어내지 않는다.
      // 루틴이 없을 때만 다음 행동을 안내한다.
      currentRoutineTimingHint: display == null
          ? '루틴 탭에서 추가할 수 있어요'
          : _timingHint(
              logStatus: h.currentRoutineLogStatus,
              hint: h.currentRoutineCard?.timingHint,
            ),
      currentRoutineStatusLabel: status,
      nextRoutineTitle: nextTitle,
      nextRoutineTime: nextTime,
      currentTime: h.clockTime,
      // 앱 원형 시간표 중앙과 같은 말을 쓴다.
      centerTimeLabel: '지금',
      ringSegments: ring,
      activeSegmentId: activeId,
    );
  }

  /// [RoutineSegment] 연속 시작 경계 → [MediumRingSegment] 호 (동심원 링용).
  static List<MediumRingSegment> _ringSegmentsFromUiSegments(
    List<RoutineSegment> segments,
  ) {
    if (segments.isEmpty) return [];
    final out = <MediumRingSegment>[];
    for (final a in segments) {
      final sweep = a.endMinutesFromMidnight - a.startMinutesFromMidnight;
      if (sweep <= 0) continue;
      out.add(
        MediumRingSegment(
          id: a.id,
          startMinutesFromMidnight: a.startMinutesFromMidnight,
          sweepMinutes: sweep,
          color: a.color,
        ),
      );
    }
    return out;
  }

  /// 이미 끝난 슬롯에서는 카운트다운을 지운다.
  ///
  /// `완료` 배지 옆에 '종료까지 31분 남음'이 함께 뜨면 두 문구가 서로를
  /// 부정한다. 끝난 상태는 더 셀 것이 없다.
  static String _timingHint({
    required RoutineLogStatus? logStatus,
    required String? hint,
  }) {
    switch (logStatus) {
      case RoutineLogStatus.completed:
      case RoutineLogStatus.skipped:
      case RoutineLogStatus.expired:
      case RoutineLogStatus.noResponse:
        return '';
      case null:
      case RoutineLogStatus.scheduled:
      case RoutineLogStatus.active:
      case RoutineLogStatus.snoozed:
        return hint ?? '';
    }
  }

  /// 상태 문구는 **진행 화면과 같은 말**을 쓴다.
  ///
  /// 예전에는 위젯만 `종료` · `응답 없음`을 써서, 같은 상태를 앱은 '놓침',
  /// 위젯은 다른 이름으로 불렀다.
  static String _statusLabel({
    required RoutineLogStatus? logStatus,
    required bool hasDisplay,
    required bool isUpcomingOnly,
  }) {
    // 보여줄 루틴이 없으면 배지 자리를 비운다. '—'는 상태가 아니다.
    if (!hasDisplay) return '';
    if (logStatus == null) {
      return isUpcomingOnly ? '예정' : '진행 중';
    }
    switch (logStatus) {
      case RoutineLogStatus.scheduled:
        return '예정';
      case RoutineLogStatus.active:
        return '진행 중';
      case RoutineLogStatus.completed:
        return '완료';
      case RoutineLogStatus.snoozed:
        return '나중에';
      case RoutineLogStatus.skipped:
        return '건너뜀';
      case RoutineLogStatus.noResponse:
      case RoutineLogStatus.expired:
        return '놓침';
    }
  }
}
