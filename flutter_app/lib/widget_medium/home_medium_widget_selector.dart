import '../application/home/home_snapshot.dart';
import '../domain/models/routine_log_status.dart';
import '../domain/utils/time_minutes.dart';
import '../l10n/app_localizations.dart';
import '../models/home_models.dart';
import 'home_medium_widget_view_model.dart';
import 'medium_ring_segment.dart';

/// [HomeSnapshot]·도메인 지표 → Medium 위젯 [HomeMediumWidgetViewModel].
///
/// 위젯 확장·iOS WidgetKit 브리지 시 동일 selector를 재사용할 수 있도록 분리.
abstract final class HomeMediumWidgetSelector {
  /// [HomeSnapshot]이 이미 [currentRoutine]·[segments]·[clockTime] 등을 포함.
  /// [l10n]은 현재 언어다. 위젯은 위젯 트리 밖에서도 만들어지므로
  /// 호출자가 넘긴다(컨트롤러의 `strings`).
  static HomeMediumWidgetViewModel fromSnapshot(
    HomeSnapshot h,
    AppLocalizations l10n,
  ) {
    final display = h.displayRoutine;
    final next = h.nextRoutine;

    final title = display?.title ?? l10n.widgetNoRoutines;

    final status = _statusLabel(
      l10n: l10n,
      logStatus: h.currentRoutineLogStatus,
      hasDisplay: display != null,
      isUpcomingOnly: h.isDisplayUpcoming,
    );

    var nextTitle = l10n.widgetNone;
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
          ? l10n.widgetAddHint
          : _timingHint(
              logStatus: h.currentRoutineLogStatus,
              hint: h.currentRoutineCard?.timingHint,
            ),
      currentRoutineStatusLabel: status,
      nextRoutineTitle: nextTitle,
      nextRoutineTime: nextTime,
      currentTime: h.clockTime,
      // 앱 원형 시간표 중앙과 같은 말을 쓴다.
      centerTimeLabel: l10n.commonNow,
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
    required AppLocalizations l10n,
    required RoutineLogStatus? logStatus,
    required bool hasDisplay,
    required bool isUpcomingOnly,
  }) {
    // 보여줄 루틴이 없으면 배지 자리를 비운다. '—'는 상태가 아니다.
    if (!hasDisplay) return '';
    if (logStatus == null) {
      return isUpcomingOnly ? l10n.statusUpcoming : l10n.statusInProgress;
    }
    switch (logStatus) {
      case RoutineLogStatus.scheduled:
        return l10n.statusUpcoming;
      case RoutineLogStatus.active:
        return l10n.statusInProgress;
      case RoutineLogStatus.completed:
        return l10n.statusCompleted;
      case RoutineLogStatus.snoozed:
        return l10n.statusSnoozed;
      case RoutineLogStatus.skipped:
        return l10n.statusSkippedShort;
      case RoutineLogStatus.noResponse:
      case RoutineLogStatus.expired:
        return l10n.statusMissed;
    }
  }
}
