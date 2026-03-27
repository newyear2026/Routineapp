import 'package:flutter/material.dart';

import '../utils/time_minutes.dart';

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
    this.notificationEnabled = true,
    this.memo,
    this.updatedAtMs = 0,
  });

  final String id;
  final String title;

  /// 0 ~ 24*60-1, 하루 내 구간 (자정 넘김 구간은 MVP에서 미지원)
  final int startMinutesFromMidnight;
  final int endMinutesFromMidnight;

  /// DateTime.weekday와 동일: 월=1 … 일=7
  final Set<int> repeatWeekdays;

  final int colorValue;
  final String iconEmoji;
  final bool notificationEnabled;
  final String? memo;

  /// 마지막 저장 시각(epoch ms) — 겹침 시 현재 슬롯 우선순위
  final int updatedAtMs;

  Color get color => Color(colorValue);

  /// 루틴 추가 폼에서 새 [Routine] 생성 (로컬 id 자동 부여)
  factory Routine.create({
    required String title,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required Set<int> repeatWeekdays,
    required int colorValue,
    bool notificationEnabled = true,
    String iconEmoji = '📌',
  }) {
    final id = 'r_${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().millisecondsSinceEpoch;
    return Routine(
      id: id,
      title: title.trim(),
      startMinutesFromMidnight: TimeMinutes.fromTimeOfDay(startTime),
      endMinutesFromMidnight: TimeMinutes.fromTimeOfDay(endTime),
      repeatWeekdays: {...repeatWeekdays},
      colorValue: colorValue,
      iconEmoji: iconEmoji,
      notificationEnabled: notificationEnabled,
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
    bool? notificationEnabled,
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
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
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
        'notificationEnabled': notificationEnabled,
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
      colorValue: rawColor & 0xFFFFFFFF,
      iconEmoji: json['iconEmoji'] as String,
      notificationEnabled: json['notificationEnabled'] as bool? ?? true,
      memo: json['memo'] as String?,
      updatedAtMs: json['updatedAtMs'] as int? ?? 0,
    );
  }
}
