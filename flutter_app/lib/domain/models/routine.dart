import 'package:flutter/material.dart';

import '../../theme/routine_palette.dart';
import '../utils/time_minutes.dart';
import 'routine_icon_id.dart';

enum RoutineType { activity, sleep }

/// 루틴 정의 — 저장소·도메인 공통 모델 (UI Color는 [colorValue]로 보관)
class Routine {
  const Routine({
    required this.id,
    required this.title,
    required this.startMinutesFromMidnight,
    required this.endMinutesFromMidnight,
    required this.repeatWeekdays,
    required this.colorValue,
    required this.iconEmoji,
    this.iconId = RoutineIconId.coffee,
    this.notificationEnabled = true,
    this.type = RoutineType.activity,
    this.wakeNotificationEnabled = false,
    this.wakeAlarmEnabled = false,
    this.bedtimeReminderEnabled = false,
    this.bedtimeReminderLeadMinutes = defaultBedtimeLeadMinutes,
    this.occurrenceDate,
    this.memo,
    this.updatedAtMs = 0,
  });

  final String id;
  final String title;

  /// Wall-clock minutes. Sleep may cross midnight; legacy activity end=1440 is preserved.
  final int startMinutesFromMidnight;
  final int endMinutesFromMidnight;

  /// 월=1 … 일=7. Activity repeats by start date; sleep repeats by wake date.
  final Set<int> repeatWeekdays;

  final int colorValue;

  /// 저장 호환용. 화면에는 [iconId] 픽셀 마크를 그린다.
  final String iconEmoji;

  /// 목록·폼·홈에서 쓰는 픽셀 아이콘.
  final RoutineIconId iconId;
  final bool notificationEnabled;
  final RoutineType type;
  final bool wakeNotificationEnabled;

  /// 기상 알림을 알람처럼 울린다 — 알람 볼륨으로, 확인할 때까지 반복.
  final bool wakeAlarmEnabled;

  /// 취침 알림. 기상 알림과 따로 켜고 끈다.
  final bool bedtimeReminderEnabled;

  /// 취침 시각보다 몇 분 먼저 알릴지. [bedtimeLeadChoices] 중 하나다.
  final int bedtimeReminderLeadMinutes;

  static const defaultBedtimeLeadMinutes = 30;
  static const bedtimeLeadChoices = [0, 15, 30, 60];

  /// Transient projection only; never persisted. Sleep records belong to the wake date.
  final DateTime? occurrenceDate;
  bool get isSleep => type == RoutineType.sleep;
  bool get crossesMidnight =>
      isSleep && endMinutesFromMidnight < startMinutesFromMidnight;
  int get durationMinutes =>
      endMinutesFromMidnight -
      startMinutesFromMidnight +
      (crossesMidnight ? 1440 : 0);
  bool get alertsEnabled =>
      isSleep ? wakeNotificationEnabled : notificationEnabled;
  bool get bedtimeAlertsEnabled => isSleep && bedtimeReminderEnabled;
  bool get wakeAlarmActive =>
      isSleep && wakeNotificationEnabled && wakeAlarmEnabled;
  String get occurrenceKey => occurrenceDate == null
      ? id
      : "${id}_${TimeMinutes.dateYmd(occurrenceDate!)}";
  final String? memo;

  /// 마지막 저장 시각(epoch ms) — 겹침 시 현재 슬롯 우선순위
  final int updatedAtMs;

  Color get color => Color(RoutinePalette.normalizeValue(colorValue));

  /// 루틴 추가 폼에서 새 [Routine] 생성 (로컬 id 자동 부여)
  factory Routine.create({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Set<int> repeatWeekdays,
    required int colorValue,
    bool notificationEnabled = true,
    RoutineType type = RoutineType.activity,
    bool wakeNotificationEnabled = false,
    bool wakeAlarmEnabled = false,
    bool bedtimeReminderEnabled = false,
    int bedtimeReminderLeadMinutes = defaultBedtimeLeadMinutes,
    String iconEmoji = '',
    RoutineIconId? iconId,
  }) {
    final id = 'r_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    return Routine(
      id: id,
      title: title.trim(),
      startMinutesFromMidnight: TimeMinutes.fromTimeOfDay(startTime),
      endMinutesFromMidnight: TimeMinutes.fromTimeOfDay(endTime),
      repeatWeekdays: {...repeatWeekdays},
      colorValue: RoutinePalette.normalizeValue(colorValue),
      iconEmoji: iconEmoji,
      iconId: iconId ?? RoutineIconId.guess(title: title),
      notificationEnabled: notificationEnabled,
      type: type,
      wakeNotificationEnabled: wakeNotificationEnabled,
      wakeAlarmEnabled: wakeAlarmEnabled,
      bedtimeReminderEnabled: bedtimeReminderEnabled,
      bedtimeReminderLeadMinutes: bedtimeReminderLeadMinutes,
      updatedAtMs: now,
    );
  }

  Routine copyWith({
    String? id,
    String? title,
    int? startMinutesFromMidnight,
    int? endMinutesFromMidnight,
    Set<int>? repeatWeekdays,
    int? colorValue,
    String? iconEmoji,
    RoutineIconId? iconId,
    bool? notificationEnabled,
    RoutineType? type,
    bool? wakeNotificationEnabled,
    bool? wakeAlarmEnabled,
    bool? bedtimeReminderEnabled,
    int? bedtimeReminderLeadMinutes,
    DateTime? occurrenceDate,
    String? memo,
    int? updatedAtMs,
  }) {
    return Routine(
      id: id ?? this.id,
      title: title ?? this.title,
      startMinutesFromMidnight:
          startMinutesFromMidnight ?? this.startMinutesFromMidnight,
      endMinutesFromMidnight:
          endMinutesFromMidnight ?? this.endMinutesFromMidnight,
      repeatWeekdays: repeatWeekdays ?? this.repeatWeekdays,
      colorValue: colorValue ?? this.colorValue,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      iconId: iconId ?? this.iconId,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      type: type ?? this.type,
      wakeNotificationEnabled:
          wakeNotificationEnabled ?? this.wakeNotificationEnabled,
      wakeAlarmEnabled: wakeAlarmEnabled ?? this.wakeAlarmEnabled,
      bedtimeReminderEnabled:
          bedtimeReminderEnabled ?? this.bedtimeReminderEnabled,
      bedtimeReminderLeadMinutes:
          bedtimeReminderLeadMinutes ?? this.bedtimeReminderLeadMinutes,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      memo: memo ?? this.memo,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'startMinutesFromMidnight': startMinutesFromMidnight,
        'endMinutesFromMidnight': endMinutesFromMidnight,
        'repeatWeekdays': repeatWeekdays.toList()..sort(),
        'colorValue': colorValue,
        'iconEmoji': iconEmoji,
        'iconId': iconId.name,
        'notificationEnabled': notificationEnabled,
        'type': type.name,
        'wakeNotificationEnabled': wakeNotificationEnabled,
        'wakeAlarmEnabled': wakeAlarmEnabled,
        'bedtimeReminderEnabled': bedtimeReminderEnabled,
        'bedtimeReminderLeadMinutes': bedtimeReminderLeadMinutes,
        'memo': memo,
        'updatedAtMs': updatedAtMs,
      };

  factory Routine.fromJson(Map<String, dynamic> json) {
    final days =
        (json['repeatWeekdays'] as List<dynamic>).map((e) => e as int).toSet();
    final rawColor = json['colorValue'] as int;
    return Routine(
      id: json['id'] as String,
      title: json['title'] as String,
      startMinutesFromMidnight: json['startMinutesFromMidnight'] as int,
      endMinutesFromMidnight: json['endMinutesFromMidnight'] as int,
      repeatWeekdays: days,
      colorValue: RoutinePalette.normalizeValue(rawColor),
      iconEmoji: json['iconEmoji'] as String? ?? '',
      iconId: json['iconId'] is String
          ? RoutineIconId.parse(json['iconId'] as String)
          : RoutineIconId.guess(
              id: json['id'] as String? ?? '',
              title: json['title'] as String? ?? '',
            ),
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      type: json['type'] == 'sleep' ? RoutineType.sleep : RoutineType.activity,
      wakeNotificationEnabled:
          json['wakeNotificationEnabled'] as bool? ?? false,
      wakeAlarmEnabled: json['wakeAlarmEnabled'] as bool? ?? false,
      bedtimeReminderEnabled: json['bedtimeReminderEnabled'] as bool? ?? false,
      bedtimeReminderLeadMinutes:
          _bedtimeLead(json['bedtimeReminderLeadMinutes']),
      memo: json['memo'] as String?,
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
    );
  }

  /// 고를 수 없는 값이 저장돼 있으면 기본값으로 돌린다.
  static int _bedtimeLead(Object? raw) =>
      raw is int && bedtimeLeadChoices.contains(raw)
          ? raw
          : defaultBedtimeLeadMinutes;
}
