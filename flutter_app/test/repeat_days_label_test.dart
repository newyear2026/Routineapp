import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/domain/utils/repeat_days_label.dart';

import 'support/localization.dart';

/// [RepeatDaysLabel]은 언어별 요일 이름이 필요해 BuildContext를 받는다.
/// 컨텍스트를 한 번 꺼내 두고 순수 함수처럼 검증한다.
Future<String Function(Set<int>)> _labeler(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    localizedApp(
      home: Builder(
        builder: (context) {
          captured = context;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return (days) => RepeatDaysLabel.of(captured, days);
}

void main() {
  testWidgets('전 요일은 매일로 요약한다', (tester) async {
    final label = await _labeler(tester);
    expect(label({1, 2, 3, 4, 5, 6, 7}), '매일');
  });

  testWidgets('월~금은 평일로 요약한다', (tester) async {
    final label = await _labeler(tester);
    expect(label({1, 2, 3, 4, 5}), '평일');
  });

  testWidgets('토·일만 있으면 주말로 요약한다', (tester) async {
    final label = await _labeler(tester);
    expect(label({6, 7}), '주말');
  });

  testWidgets('그 외에는 요일을 순서대로 나열한다', (tester) async {
    final label = await _labeler(tester);
    expect(label({3, 1, 5}), '월 · 수 · 금');
    expect(label({7}), '일');
  });

  testWidgets('빈 집합은 반복 없음이다', (tester) async {
    final label = await _labeler(tester);
    expect(label(const {}), '반복 없음');
  });

  testWidgets('평일·주말에 맞지 않으면 나열로 떨어진다', (tester) async {
    final label = await _labeler(tester);
    expect(label({1, 2, 3, 4}), '월 · 화 · 수 · 목');
    expect(label({1, 2, 3, 4, 5, 6}), '월 · 화 · 수 · 목 · 금 · 토');
  });
}
