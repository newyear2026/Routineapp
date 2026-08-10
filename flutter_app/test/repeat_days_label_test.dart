import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/utils/repeat_days_label.dart';

void main() {
  test('전 요일은 매일로 요약한다', () {
    expect(RepeatDaysLabel.of({1, 2, 3, 4, 5, 6, 7}), '매일');
  });

  test('월~금은 평일로 요약한다', () {
    expect(RepeatDaysLabel.of({1, 2, 3, 4, 5}), '평일');
  });

  test('토·일만 있으면 주말로 요약한다', () {
    expect(RepeatDaysLabel.of({6, 7}), '주말');
  });

  test('그 외에는 요일을 순서대로 나열한다', () {
    expect(RepeatDaysLabel.of({3, 1, 5}), '월 · 수 · 금');
    expect(RepeatDaysLabel.of({7}), '일');
  });

  test('선택된 요일이 없으면 반복 없음이다', () {
    expect(RepeatDaysLabel.of(const {}), '반복 없음');
  });

  test('평일 전체가 아니면 평일로 뭉뚱그리지 않는다', () {
    expect(RepeatDaysLabel.of({1, 2, 3, 4}), '월 · 화 · 수 · 목');
    expect(RepeatDaysLabel.of({1, 2, 3, 4, 5, 6}), '월 · 화 · 수 · 목 · 금 · 토');
  });
}
