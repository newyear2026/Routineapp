import '../models/routine.dart';
import '../utils/time_minutes.dart';

/// 온보딩 «추천 루틴» 한 줄 — UI·저장 공통 스펙.
class RecommendedRoutineDefinition {
  const RecommendedRoutineDefinition({
    required this.catalogId,
    required this.title,
    required this.emoji,
    required this.startMinutesFromMidnight,
    required this.durationMinutes,
    required this.colorValue,
    this.showRecommendedBadge = false,
  });

  /// 저장 시 Routine.id 접두사와 함께 쓰는 안정 키 (`onboarding_rec_$catalogId`).
  final String catalogId;
  final String title;
  final String emoji;
  final int startMinutesFromMidnight;

  /// 종료 시각 = 시작 + duration (같은 날, 24:00 미만으로 클램프).
  final int durationMinutes;
  final int colorValue;
  final bool showRecommendedBadge;

  String get timeLabel => TimeMinutes.formatHm(startMinutesFromMidnight);

  Routine toRoutine() {
    final endRaw = startMinutesFromMidnight + durationMinutes;
    final end = endRaw >= 24 * 60 ? 24 * 60 - 1 : endRaw;
    final now = DateTime.now().millisecondsSinceEpoch;
    return Routine(
      id: 'onboarding_rec_$catalogId',
      title: title,
      startMinutesFromMidnight: startMinutesFromMidnight,
      endMinutesFromMidnight: end,
      repeatWeekdays: {1, 2, 3, 4, 5, 6, 7},
      colorValue: colorValue,
      iconEmoji: emoji,
      notificationEnabled: true,
      updatedAtMs: now,
    );
  }
}

/// 온보딩 루틴 선택 화면과 동일 순서·기본 선택 상태.
abstract final class RecommendedRoutineCatalog {
  RecommendedRoutineCatalog._();

  static const List<RecommendedRoutineDefinition> items = [
    RecommendedRoutineDefinition(
      catalogId: 'wake',
      title: '기상',
      emoji: '🌅',
      startMinutesFromMidnight: 7 * 60,
      durationMinutes: 60,
      colorValue: 0xFFFFE4E9,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'exercise',
      title: '운동',
      emoji: '💪',
      startMinutesFromMidnight: 7 * 60 + 30,
      durationMinutes: 60,
      colorValue: 0xFFFFD4E0,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'breakfast',
      title: '아침식사',
      emoji: '🍳',
      startMinutesFromMidnight: 9 * 60,
      durationMinutes: 60,
      colorValue: 0xFFFFE9D4,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'study',
      title: '공부',
      emoji: '📚',
      startMinutesFromMidnight: 10 * 60,
      durationMinutes: 120,
      colorValue: 0xFFE8DDFA,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'lunch',
      title: '점심식사',
      emoji: '🍱',
      startMinutesFromMidnight: 12 * 60,
      durationMinutes: 60,
      colorValue: 0xFFFFDDC5,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'rest',
      title: '휴식',
      emoji: '☕',
      startMinutesFromMidnight: 15 * 60,
      durationMinutes: 60,
      colorValue: 0xFFD4E4FF,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'dinner',
      title: '저녁식사',
      emoji: '🍽️',
      startMinutesFromMidnight: 18 * 60,
      durationMinutes: 60,
      colorValue: 0xFFFFE4E9,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'sleep',
      title: '취침',
      emoji: '🌙',
      startMinutesFromMidnight: 23 * 60,
      durationMinutes: 60,
      colorValue: 0xFFD4C5F0,
    ),
  ];

  /// 기존 UI와 동일한 기본 선택 (공부·휴식 미선택).
  static const List<bool> defaultSelection = [
    true,
    true,
    true,
    false,
    true,
    false,
    true,
    true,
  ];
}
