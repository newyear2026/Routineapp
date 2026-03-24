import 'time_minutes.dart';

/// 하루 내 구간·분 단위 비교 — UI/서비스와 무관한 순수 함수
abstract final class TimeCalculation {
  /// 자정 넘김 없이 `[start, end)` 구간에 분 `m`이 포함되는지 (MVP)
  static bool containsMinuteInOpenInterval(
    int m,
    int startInclusive,
    int endExclusive,
  ) {
    if (endExclusive > startInclusive) {
      return m >= startInclusive && m < endExclusive;
    }
    return false;
  }

  /// 두 시각(분) 사이 경과 비율 0.0 ~ 1.0, 구간 밖이면 null
  static double? elapsedRatioInInterval(
    int m,
    int startInclusive,
    int endExclusive,
  ) {
    if (!containsMinuteInOpenInterval(m, startInclusive, endExclusive)) {
      return null;
    }
    final dur = endExclusive - startInclusive;
    if (dur <= 0) return null;
    return ((m - startInclusive) / dur).clamp(0.0, 1.0);
  }

  /// [dateLocal]의 `yyyy-MM-dd`
  static String dateYmd(DateTime dateLocal) => TimeMinutes.dateYmd(dateLocal);
}
