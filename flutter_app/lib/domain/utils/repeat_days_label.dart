/// 반복 요일 집합을 사람이 읽는 한 줄로 요약한다.
///
/// 루틴 목록·폼·미리보기가 같은 문구를 쓰도록 한곳에 둔다.
abstract final class RepeatDaysLabel {
  static const _labels = ['월', '화', '수', '목', '금', '토', '일'];
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _weekend = {6, 7};

  /// [repeatWeekdays]는 월=1 … 일=7.
  static String of(Set<int> repeatWeekdays) {
    if (repeatWeekdays.isEmpty) return '반복 없음';
    if (repeatWeekdays.length == 7) return '매일';
    if (repeatWeekdays.length == _weekdays.length &&
        repeatWeekdays.containsAll(_weekdays)) {
      return '평일';
    }
    if (repeatWeekdays.length == _weekend.length &&
        repeatWeekdays.containsAll(_weekend)) {
      return '주말';
    }

    final sorted = repeatWeekdays.toList()..sort();
    return sorted
        .where((day) => day >= 1 && day <= 7)
        .map((day) => _labels[day - 1])
        .join(' · ');
  }
}
