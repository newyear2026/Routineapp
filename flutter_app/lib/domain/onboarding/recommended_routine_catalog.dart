import '../models/routine.dart';
import '../utils/time_minutes.dart';
import '../../theme/routine_palette.dart';
import '../models/routine_icon_id.dart';

/// 온보딩 «추천 루틴» 한 줄 — UI·저장 공통 스펙.
class RecommendedRoutineDefinition {
  const RecommendedRoutineDefinition({
    required this.catalogId,
    required this.startMinutesFromMidnight,
    required this.durationMinutes,
    required this.colorValue,
    this.showRecommendedBadge = false,
  });

  /// 저장 시 Routine.id 접두사와 함께 쓰는 안정 키 (`onboarding_rec_$catalogId`).
  ///
  /// 이름은 여기 두지 않는다 — 사용자가 고른 언어로 저장되어야 하므로
  /// 화면이 현재 언어의 이름을 [toRoutine]에 넘긴다.
  final String catalogId;
  final int startMinutesFromMidnight;

  /// 종료 시각 = 시작 + duration (같은 날, 24:00 미만으로 클램프).
  final int durationMinutes;
  final int colorValue;
  final bool showRecommendedBadge;

  String get timeLabel => TimeMinutes.formatHm(startMinutesFromMidnight);

  /// [title]은 화면이 현재 언어로 고른 이름이다.
  Routine toRoutine(String title) {
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
      iconEmoji: '',
      iconId: RoutineIconId.fromCatalogId(catalogId),
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
      startMinutesFromMidnight: 7 * 60,
      durationMinutes: 30,
      colorValue: RoutinePalette.coralValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'exercise',
      startMinutesFromMidnight: 7 * 60 + 30,
      durationMinutes: 30,
      colorValue: RoutinePalette.roseValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'breakfast',
      startMinutesFromMidnight: 8 * 60,
      durationMinutes: 30,
      colorValue: RoutinePalette.amberValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'study',
      startMinutesFromMidnight: 9 * 60,
      durationMinutes: 120,
      colorValue: RoutinePalette.lavenderValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'lunch',
      startMinutesFromMidnight: 12 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.orangeValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'rest',
      startMinutesFromMidnight: 15 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.blueValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'dinner',
      startMinutesFromMidnight: 18 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.greenValue,
    ),
    RecommendedRoutineDefinition(
      catalogId: 'sleep',
      startMinutesFromMidnight: 23 * 60,
      durationMinutes: 60,
      colorValue: RoutinePalette.violetValue,
    ),
  ];

  /// 시안과 같은 기본 선택: 기상 · 아침 식사 · 휴식 · 저녁 식사.
  static const List<bool> defaultSelection = [
    true,
    false,
    true,
    false,
    false,
    true,
    true,
    false,
  ];
}
