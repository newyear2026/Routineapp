/// 루틴 추가 폼 검증 — UI 문자열만 반환
abstract final class RoutineFormValidator {
  static String? validateTitle(String title) {
    final t = title.trim();
    if (t.isEmpty) return '루틴 이름을 입력해 주세요.';
    if (t.length > 80) return '이름은 80자 이하로 입력해 주세요.';
    return null;
  }

  /// MVP: 같은 날 안에서만 구간 허용 (자정 넘김 미지원)
  static String? validateTimeRange(int startMinutes, int endMinutes) {
    if (startMinutes >= endMinutes) {
      return '종료 시간은 시작 시간보다 늦어야 해요.';
    }
    return null;
  }

  static String? validateRepeatDays(Set<int> weekdays) {
    if (weekdays.isEmpty) {
      return '반복 요일을 하루 이상 선택해 주세요.';
    }
    return null;
  }
}
