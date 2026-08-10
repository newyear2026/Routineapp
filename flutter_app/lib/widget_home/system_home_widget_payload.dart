import 'dart:convert';

import '../application/home/home_snapshot.dart';
import '../domain/utils/time_minutes.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import '../widget_medium/home_medium_widget_view_model.dart';
import '../widget_medium/medium_ring_segment.dart';
import '../widget_medium/mini_circular_timetable.dart';

/// 시스템 홈 위젯(iOS/Android)과 공유하는 JSON 페이로드 — [docs/SYSTEM_HOME_WIDGET_SPEC.md].
class SystemHomeWidgetPayload {
  const SystemHomeWidgetPayload({
    required this.schemaVersion,
    required this.currentRoutineTitle,
    required this.currentRoutineStatus,
    required this.currentRoutineTimingHint,
    required this.nextRoutineTitle,
    required this.nextRoutineTime,
    required this.currentTimeHour,
    required this.currentTimeMinute,
    required this.pointerAngleRad,
    required this.centerTimeLabel,
    required this.ringSegments,
    this.activeSegmentId,
  });

  /// v2: 렌더링하지 않는 `headerTitle`·`subtitle`·`nextRoutineLine`·`currentRoutineTimeRange`·`currentRoutineIconEmoji`를 빼고
  /// `currentRoutineTimingHint`를 넣었다.
  /// 네이티브 디코더는 없는 필드에 깨지지 않도록 모두 옵셔널로 읽는다.
  static const currentSchemaVersion = 2;
  static const storageKey = 'routine_widget_payload';

  final int schemaVersion;
  final String currentRoutineTitle;
  final String currentRoutineStatus;
  final String currentRoutineTimingHint;
  final String nextRoutineTitle;
  final String nextRoutineTime;
  final int currentTimeHour;
  final int currentTimeMinute;
  final double pointerAngleRad;
  final String centerTimeLabel;
  final List<SystemRingSegmentPayload> ringSegments;
  final String? activeSegmentId;

  factory SystemHomeWidgetPayload.fromHomeSnapshot(HomeSnapshot snapshot) {
    final vm = HomeMediumWidgetSelector.fromSnapshot(snapshot);
    return SystemHomeWidgetPayload.fromViewModel(vm, snapshot);
  }

  factory SystemHomeWidgetPayload.fromViewModel(
    HomeMediumWidgetViewModel vm,
    HomeSnapshot snapshot,
  ) {
    final nextCard = snapshot.nextRoutineCard;
    final nextR = snapshot.nextRoutine;
    final nextTitle = nextCard?.name ?? nextR?.title ?? '';
    final nextTime = nextCard?.time ??
        (nextR != null ? TimeMinutes.formatHm(nextR.startMinutesFromMidnight) : '');

    final t = vm.currentTime;
    final ptr =
        vm.pointerAngleRad ?? MiniCircularTimetable.pointerAngleFromTime(t);

    return SystemHomeWidgetPayload(
      schemaVersion: currentSchemaVersion,
      currentRoutineTitle: vm.currentRoutineTitle,
      currentRoutineStatus: vm.currentRoutineStatusLabel,
      currentRoutineTimingHint: vm.currentRoutineTimingHint,
      nextRoutineTitle: nextTitle,
      nextRoutineTime: nextTime,
      currentTimeHour: t.hour,
      currentTimeMinute: t.minute,
      pointerAngleRad: ptr,
      centerTimeLabel: vm.centerTimeLabel,
      ringSegments:
          vm.ringSegments.map(SystemRingSegmentPayload.fromMedium).toList(),
      activeSegmentId: vm.activeSegmentId,
    );
  }


  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'currentRoutineTitle': currentRoutineTitle,
        'currentRoutineStatus': currentRoutineStatus,
        'currentRoutineTimingHint': currentRoutineTimingHint,
        'nextRoutineTitle': nextRoutineTitle,
        'nextRoutineTime': nextRoutineTime,
        'currentTimeHour': currentTimeHour,
        'currentTimeMinute': currentTimeMinute,
        'pointerAngleRad': pointerAngleRad,
        'centerTimeLabel': centerTimeLabel,
        'ringSegments': ringSegments.map((e) => e.toJson()).toList(),
        'activeSegmentId': activeSegmentId,
      };

  String encode() => jsonEncode(toJson());
}

class SystemRingSegmentPayload {
  const SystemRingSegmentPayload({
    required this.id,
    required this.startMinutesFromMidnight,
    required this.sweepMinutes,
    required this.colorArgb,
  });

  factory SystemRingSegmentPayload.fromMedium(MediumRingSegment s) {
    return SystemRingSegmentPayload(
      id: s.id,
      startMinutesFromMidnight: s.startMinutesFromMidnight,
      sweepMinutes: s.sweepMinutes,
      colorArgb: s.color.toARGB32(),
    );
  }

  final String id;
  final int startMinutesFromMidnight;
  final int sweepMinutes;
  final int colorArgb;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startMinutesFromMidnight': startMinutesFromMidnight,
        'sweepMinutes': sweepMinutes,
        'colorArgb': colorArgb,
      };
}
