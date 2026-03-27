import 'dart:convert';

import '../application/home/home_snapshot.dart';
import '../widget_medium/home_medium_widget_selector.dart';
import '../widget_medium/home_medium_widget_view_model.dart';
import '../widget_medium/medium_ring_segment.dart';
import '../widget_medium/mini_circular_timetable.dart';

/// 시스템 홈 위젯(iOS/Android)과 공유하는 JSON 페이로드 — [docs/SYSTEM_HOME_WIDGET_SPEC.md].
class SystemHomeWidgetPayload {
  const SystemHomeWidgetPayload({
    required this.schemaVersion,
    required this.headerTitle,
    required this.subtitle,
    required this.currentRoutineTitle,
    required this.currentRoutineIconEmoji,
    required this.currentRoutineTimeRange,
    required this.currentRoutineStatus,
    required this.nextRoutineLine,
    required this.nextRoutineTitle,
    required this.nextRoutineTime,
    required this.currentTimeHour,
    required this.currentTimeMinute,
    required this.pointerAngleRad,
    required this.centerTimeLabel,
    required this.ringSegments,
    this.activeSegmentId,
  });

  static const currentSchemaVersion = 1;
  static const storageKey = 'routine_widget_payload';

  final int schemaVersion;
  final String headerTitle;
  final String subtitle;
  final String currentRoutineTitle;
  final String currentRoutineIconEmoji;
  final String currentRoutineTimeRange;
  final String currentRoutineStatus;
  final String nextRoutineLine;
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
        (nextR != null ? _hm(nextR.startMinutesFromMidnight) : '');

    final t = vm.currentTime;
    final ptr =
        vm.pointerAngleRad ?? MiniCircularTimetable.pointerAngleFromTime(t);

    return SystemHomeWidgetPayload(
      schemaVersion: currentSchemaVersion,
      headerTitle: vm.headerTitle,
      subtitle: vm.subtitle,
      currentRoutineTitle: vm.currentRoutineTitle,
      currentRoutineIconEmoji: vm.currentRoutineIconEmoji,
      currentRoutineTimeRange: vm.currentRoutineTimeRange,
      currentRoutineStatus: vm.currentRoutineStatusLabel,
      nextRoutineLine: vm.nextRoutineLine,
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

  static String _hm(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'headerTitle': headerTitle,
        'subtitle': subtitle,
        'currentRoutineTitle': currentRoutineTitle,
        'currentRoutineIconEmoji': currentRoutineIconEmoji,
        'currentRoutineTimeRange': currentRoutineTimeRange,
        'currentRoutineStatus': currentRoutineStatus,
        'nextRoutineLine': nextRoutineLine,
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
