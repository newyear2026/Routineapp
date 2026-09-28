import 'dart:convert';

import '../application/home/home_snapshot.dart';
import '../l10n/app_localizations.dart';
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
    this.nextLabel = '',
    this.refreshHint = '',
    this.validUntilEpochMs = 0,
    this.timelineStates = const [],
    this.timingStartTemplate = '',
    this.timingEndTemplate = '',
    this.durationHoursMinutesTemplate = '',
    this.durationHoursTemplate = '',
    this.durationMinutesTemplate = '',
    this.characterPackId = 'cat_starlight',
  });

  /// v3: 미래 루틴 경계·다국어 표시 템플릿·만료 시점을 추가했다.
  /// 네이티브 디코더는 없는 필드에 깨지지 않도록 모두 옵셔널로 읽는다.
  static const currentSchemaVersion = 3;
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
  final String nextLabel;
  final String refreshHint;
  final int validUntilEpochMs;
  final List<SystemWidgetStatePayload> timelineStates;
  final String timingStartTemplate;
  final String timingEndTemplate;
  final String durationHoursMinutesTemplate;
  final String durationHoursTemplate;
  final String durationMinutesTemplate;
  final String characterPackId;

  factory SystemHomeWidgetPayload.fromHomeSnapshot(
    HomeSnapshot snapshot,
    AppLocalizations l10n,
  ) {
    final vm = HomeMediumWidgetSelector.fromSnapshot(snapshot, l10n);
    return SystemHomeWidgetPayload.fromViewModel(vm);
  }

  factory SystemHomeWidgetPayload.fromViewModel(
    HomeMediumWidgetViewModel vm,
  ) {
    final t = vm.currentTime;
    final ptr =
        vm.pointerAngleRad ?? MiniCircularTimetable.pointerAngleFromTime(t);

    return SystemHomeWidgetPayload(
      schemaVersion: currentSchemaVersion,
      currentRoutineTitle: vm.currentRoutineTitle,
      currentRoutineStatus: vm.currentRoutineStatusLabel,
      currentRoutineTimingHint: vm.currentRoutineTimingHint,
      nextRoutineTitle: vm.nextRoutineTitle,
      nextRoutineTime: vm.nextRoutineTime,
      currentTimeHour: t.hour,
      currentTimeMinute: t.minute,
      pointerAngleRad: ptr,
      centerTimeLabel: vm.centerTimeLabel,
      ringSegments:
          vm.ringSegments.map(SystemRingSegmentPayload.fromMedium).toList(),
      activeSegmentId: vm.activeSegmentId,
    );
  }

  SystemHomeWidgetPayload withTimeline({
    required AppLocalizations l10n,
    required int validUntilEpochMs,
    required List<SystemWidgetStatePayload> states,
  }) =>
      SystemHomeWidgetPayload(
        schemaVersion: schemaVersion,
        currentRoutineTitle: currentRoutineTitle,
        currentRoutineStatus: currentRoutineStatus,
        currentRoutineTimingHint: currentRoutineTimingHint,
        nextRoutineTitle: nextRoutineTitle,
        nextRoutineTime: nextRoutineTime,
        currentTimeHour: currentTimeHour,
        currentTimeMinute: currentTimeMinute,
        pointerAngleRad: pointerAngleRad,
        centerTimeLabel: centerTimeLabel,
        ringSegments: ringSegments,
        activeSegmentId: activeSegmentId,
        nextLabel: l10n.commonNext,
        refreshHint: l10n.widgetRefreshHint,
        validUntilEpochMs: validUntilEpochMs,
        timelineStates: states,
        timingStartTemplate: l10n.timingUntilStart('{duration}'),
        timingEndTemplate: l10n.timingUntilEnd('{duration}'),
        durationHoursMinutesTemplate: l10n
            .durationHoursMinutes(101, 202)
            .replaceFirst('101', '{hours}')
            .replaceFirst('202', '{minutes}'),
        durationHoursTemplate:
            l10n.durationHours(101).replaceFirst('101', '{hours}'),
        durationMinutesTemplate:
            l10n.durationMinutes(202).replaceFirst('202', '{minutes}'),
        characterPackId: characterPackId,
      );

  SystemHomeWidgetPayload withCharacterPack(String packId) =>
      SystemHomeWidgetPayload(
        schemaVersion: schemaVersion,
        currentRoutineTitle: currentRoutineTitle,
        currentRoutineStatus: currentRoutineStatus,
        currentRoutineTimingHint: currentRoutineTimingHint,
        nextRoutineTitle: nextRoutineTitle,
        nextRoutineTime: nextRoutineTime,
        currentTimeHour: currentTimeHour,
        currentTimeMinute: currentTimeMinute,
        pointerAngleRad: pointerAngleRad,
        centerTimeLabel: centerTimeLabel,
        ringSegments: ringSegments,
        activeSegmentId: activeSegmentId,
        nextLabel: nextLabel,
        refreshHint: refreshHint,
        validUntilEpochMs: validUntilEpochMs,
        timelineStates: timelineStates,
        timingStartTemplate: timingStartTemplate,
        timingEndTemplate: timingEndTemplate,
        durationHoursMinutesTemplate: durationHoursMinutesTemplate,
        durationHoursTemplate: durationHoursTemplate,
        durationMinutesTemplate: durationMinutesTemplate,
        characterPackId: packId,
      );

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
        'nextLabel': nextLabel,
        'refreshHint': refreshHint,
        'validUntilEpochMs': validUntilEpochMs,
        'timelineStates': timelineStates.map((e) => e.toJson()).toList(),
        'timingStartTemplate': timingStartTemplate,
        'timingEndTemplate': timingEndTemplate,
        'durationHoursMinutesTemplate': durationHoursMinutesTemplate,
        'durationHoursTemplate': durationHoursTemplate,
        'durationMinutesTemplate': durationMinutesTemplate,
        'characterPackId': characterPackId,
      };

  String encode() => jsonEncode(toJson());
}

/// 앱이 꺼져 있어도 네이티브 위젯이 미래의 루틴 경계에서 고를 수 있는 상태.
class SystemWidgetStatePayload {
  const SystemWidgetStatePayload({
    required this.effectiveAtEpochMs,
    required this.currentRoutineTitle,
    required this.currentRoutineStatus,
    required this.currentRoutineTimingHint,
    required this.nextRoutineTitle,
    required this.nextRoutineTime,
    required this.centerTimeLabel,
    required this.ringSegments,
    this.activeSegmentId,
    this.timingTargetEpochMs,
    this.timingMode,
  });

  final int effectiveAtEpochMs;
  final String currentRoutineTitle;
  final String currentRoutineStatus;
  final String currentRoutineTimingHint;
  final String nextRoutineTitle;
  final String nextRoutineTime;
  final String centerTimeLabel;
  final List<SystemRingSegmentPayload> ringSegments;
  final String? activeSegmentId;
  final int? timingTargetEpochMs;
  final String? timingMode;

  Map<String, dynamic> toJson() => {
        'effectiveAtEpochMs': effectiveAtEpochMs,
        'currentRoutineTitle': currentRoutineTitle,
        'currentRoutineStatus': currentRoutineStatus,
        'currentRoutineTimingHint': currentRoutineTimingHint,
        'nextRoutineTitle': nextRoutineTitle,
        'nextRoutineTime': nextRoutineTime,
        'centerTimeLabel': centerTimeLabel,
        'ringSegments': ringSegments.map((e) => e.toJson()).toList(),
        'activeSegmentId': activeSegmentId,
        'timingTargetEpochMs': timingTargetEpochMs,
        'timingMode': timingMode,
      };
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
