import 'package:flutter/material.dart';

/// Home 화면용 모델 — [Routine]에서 매핑 (원형 시간표 위치는 분 단위)
class RoutineSegment {
  const RoutineSegment({
    required this.id,
    required this.startMinutesFromMidnight,
    required this.label,
    required this.emoji,
    required this.color,
  });

  final String id;

  /// 0 ~ 1439 — 원형 링 각도·구간 계산에 사용
  final int startMinutesFromMidnight;
  final String label;
  final String emoji;
  final Color color;

  /// 시 단위 표시/레거시 호환
  int get startHour => startMinutesFromMidnight ~/ 60;
}

class CurrentRoutine {
  const CurrentRoutine({
    required this.id,
    required this.name,
    required this.emoji,
    required this.startTime,
    required this.endTime,
    required this.progress,
    required this.repeatDays,
    required this.memo,
  });

  final String id;
  final String name;
  final String emoji;
  final String startTime;
  final String endTime;
  final int progress;
  final List<String> repeatDays;
  final String memo;
}

class NextRoutine {
  const NextRoutine({
    required this.name,
    required this.emoji,
    required this.time,
  });

  final String name;
  final String emoji;
  final String time;
}

class HomeProgress {
  const HomeProgress({required this.completed, required this.total});

  final int completed;
  final int total;
}

class CharacterCopy {
  const CharacterCopy({
    required this.emoji,
    required this.highlightEmoji,
    required this.highlightRoutineName,
  });

  final String emoji;
  final String highlightEmoji;
  final String highlightRoutineName;
}
