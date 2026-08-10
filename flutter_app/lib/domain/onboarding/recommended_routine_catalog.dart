import '../models/routine.dart';
import '../utils/time_minutes.dart';
import '../../theme/routine_palette.dart';

/// 온보딩 «추천 루틴» 한 줄 — UI·저장 공통 스펙.
class RecommendedRoutineDefinition {
  const RecommendedRoutineDefinition({
    required this.catalogId,
    required this.title,
    required this.startMinutesFromMidnight,
    required this.durationMinutes,
    required this.colorValue,
    this.showRecommendedBadge = false,
  });

  /// 저장 시 Routine.id 접두사와 함께 쓰는 안정 키 (`onboarding_rec_$catalogId`).
  final String catalogId;
  final String title;
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
      // 루틴의 정체성은 색상으로 표현한다. 기존 데이터 모델의 필드는
      // 마이그레이션 호환성을 위해 유지하되 새 추천 루틴에는 저장하지 않는다.
      iconEmoji: '',
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
      startMinutesFromMidnight: 7 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.coralValue,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'exercise',
      title: '운동',
      startMinutesFromMidnight: 7 * 60 + 30,
      durationMinutes: 60,
      colorValue: RoutinePalette.roseValue,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'breakfast',
      title: '아침식사',
      startMinutesFromMidnight: 9 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.amberValue,
      showRecommendedBadge: true,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'study',
      title: '공부',
      startMinutesFromMidnight: 10 * 60,
      durationMinutes: 120,
      colorValue: RoutinePalette.lavenderValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'lunch',
      title: '점심식사',
      startMinutesFromMidnight: 12 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.orangeValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'rest',
      title: '휴식',
      startMinutesFromMidnight: 15 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.blueValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'dinner',
      title: '저녁식사',
      startMinutesFromMidnight: 18 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.greenValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'sleep',
      title: '취침',
      startMinutesFromMidnight: 23 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.violetValue,
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
