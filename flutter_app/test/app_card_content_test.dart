import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/app_card.dart';

void main() {
  testWidgets('카드 안의 정보와 조작이 기본·강조 스타일 모두에서 유지된다', (tester) async {
    var calls = 0;
    for (final variant in AppCardVariant.values) {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: AppCard(
        variant: variant,
        child: Column(children: [
          const Text('오늘 진행 3 / 5'),
          TextButton(onPressed: () => calls++, child: const Text('상세 보기'))
        ]),
      ))));
      expect(find.text('오늘 진행 3 / 5'), findsOneWidget);
      await tester.tap(find.text('상세 보기'));
      await tester.pumpAndSettle();
    }
    expect(calls, 2);
  });
}
