/// 루틴 추가 폼에서 무엇이 잘못됐는지.
///
/// 검증 규칙은 언어와 무관하다. 문장을 여기서 만들면 도메인이 번역을 들고
/// 있게 되므로(PROJECT_RULES 4), 종류만 돌려주고 문장은 화면이 고른다.
enum RoutineFormError {
  titleEmpty,
  titleTooLong,
  endBeforeStart,
  noRepeatDays,
}

/// 루틴 추가 폼 검증 — 규칙만 판단한다
abstract final class RoutineFormValidator {
  static RoutineFormError? validateTitle(String title) {
    final t = title.trim();
    if (t.isEmpty) return RoutineFormError.titleEmpty;
    if (t.length > 80) return RoutineFormError.titleTooLong;
    return null;
  }

  /// MVP: 같은 날 안에서만 구간 허용 (자정 넘김 미지원)
  static RoutineFormError? validateTimeRange(int startMinutes, int endMinutes) {
    if (startMinutes >= endMinutes) return RoutineFormError.endBeforeStart;
    return null;
  }

  static RoutineFormError? validateRepeatDays(Set<int> weekdays) {
    if (weekdays.isEmpty) return RoutineFormError.noRepeatDays;
    return null;
  }
}
