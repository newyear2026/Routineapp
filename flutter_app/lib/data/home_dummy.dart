import 'package:flutter/material.dart';
import '../models/home_models.dart';

/// 정적 UI용 더미 — 한 파일에서만 교체하면 Home 전체가 따라감
const homeDummyClockHour = 14;
const homeDummyClockMinute = 30;

final homeDummySegments = <RoutineSegment>[
  RoutineSegment(
    id: 'wake',
    startHour: 6,
    label: '기상',
    emoji: '🌅',
    color: Color(0xFFFFE4E9),
  ),
  RoutineSegment(
    id: 'workout',
    startHour: 7,
    label: '운동',
    emoji: '💪',
    color: Color(0xFFFFD4E0),
  ),
  RoutineSegment(
    id: 'breakfast',
    startHour: 9,
    label: '아침',
    emoji: '🍳',
    color: Color(0xFFFFE9D4),
  ),
  RoutineSegment(
    id: 'study',
    startHour: 10,
    label: '공부',
    emoji: '📚',
    color: Color(0xFFE8DDFA),
  ),
  RoutineSegment(
    id: 'lunch',
    startHour: 12,
    label: '점심',
    emoji: '🍱',
    color: Color(0xFFFFDDC5),
  ),
  RoutineSegment(
    id: 'rest',
    startHour: 15,
    label: '휴식',
    emoji: '☕',
    color: Color(0xFFD4E4FF),
  ),
  RoutineSegment(
    id: 'dinner',
    startHour: 18,
    label: '저녁',
    emoji: '🍽️',
    color: Color(0xFFFFE4E9),
  ),
  RoutineSegment(
    id: 'sleep',
    startHour: 23,
    label: '취침',
    emoji: '🌙',
    color: Color(0xFFD4C5F0),
  ),
];

const homeDummyCurrentRoutine = CurrentRoutine(
  id: 'study',
  name: '공부',
  emoji: '📚',
  startTime: '14:00',
  endTime: '16:00',
  progress: 25,
  repeatDays: ['월', '화', '수', '목', '금'],
  memo: '휴대폰은 잠시 멀리 두고, 지금은 학습에만 집중해봐요.',
);

const homeDummyNextRoutine = NextRoutine(
  name: '휴식',
  emoji: '☕',
  time: '16:00',
);

const homeDummyProgress = HomeProgress(completed: 3, total: 8);

const homeDummyCharacter = CharacterCopy(
  emoji: '🐻',
  highlightEmoji: '📚',
  highlightRoutineName: '공부',
);
