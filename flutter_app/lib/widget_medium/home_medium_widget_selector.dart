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

    final title = display?.title ?? '오늘 루틴 없음';
    final emoji = display?.iconEmoji ?? '📌';

    var timeRange = '—';
    if (display != null) {
      timeRange =
          '${TimeMinutes.formatHm(display.startMinutesFromMidnight)} - ${TimeMinutes.formatHm(display.endMinutesFromMidnight)}';
    }

    final status = _statusLabel(
      logStatus: h.currentRoutineLogStatus,
      hasDisplay: display != null,
      isUpcomingOnly: h.isDisplayUpcoming,
    );

    var nextLine = '다음 루틴이 없어요';
    if (h.nextRoutineCard != null) {
      final n = h.nextRoutineCard!;
      nextLine = '다음: ${n.name} (${n.time})';
    } else if (next != null) {
      nextLine =
          '다음: ${next.title} (${TimeMinutes.formatHm(next.startMinutesFromMidnight)})';
    }

    final ring = _ringSegmentsFromUiSegments(h.segments);
    final activeId = h.activeRoutineForRing?.id;

    return HomeMediumWidgetViewModel(
      headerTitle: '하루 루틴 시간표',
      subtitle: '오늘 루틴 진행 중',
      currentRoutineTitle: title,
      currentRoutineIconEmoji: emoji,
      currentRoutineTimeRange: timeRange,
      currentRoutineStatusLabel: status,
      nextRoutineLine: nextLine,
      currentTime: h.clockTime,
      centerTimeLabel: '현재 시간',
      ringSegments: ring,
      activeSegmentId: activeId,
    );
  }

  /// [RoutineSegment] 연속 시작 경계 → [MediumRingSegment] 호 (동심원 링용).
  static List<MediumRingSegment> _ringSegmentsFromUiSegments(
    List<RoutineSegment> segments,
  ) {
    if (segments.isEmpty) return [];
    final n = segments.length;
    final out = <MediumRingSegment>[];
    for (var i = 0; i < n; i++) {
      final a = segments[i];
      final b = segments[(i + 1) % n];
      var sweep = b.startMinutesFromMidnight - a.startMinutesFromMidnight;
      if (sweep <= 0) sweep += 24 * 60;
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

  static String _statusLabel({
    required RoutineLogStatus? logStatus,
    required bool hasDisplay,
    required bool isUpcomingOnly,
  }) {
    if (!hasDisplay) return '—';
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
        return '응답 없음';
      case RoutineLogStatus.expired:
        return '종료';
    }
  }
}
