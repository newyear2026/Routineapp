import 'package:flutter/material.dart';

/// Home 화면용 모델 — 이후 상태/저장소와 연결
class RoutineSegment {
  const RoutineSegment({
    required this.id,
    required this.startHour,
    required this.label,
    required this.emoji,
    required this.color,
  });

  final String id;
  final int startHour;
  final String label;
  final String emoji;
  final Color color;
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
