import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/app_button.dart';

void main() {
  testWidgets('픽셀 버튼은 한 번 실행되며 취소한 누름은 실행되지 않는다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: AppButton(label: '완료', onPressed: () => calls++),
    )));
    final button = find.byType(AppButton);
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump(const Duration(milliseconds: 150));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(calls, 0);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 2);
  });

  testWidgets('로딩 중에는 라벨과 진행 표시를 유지하고 중복 실행을 막는다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
      body: AppButton(
          label: '저장',
          icon: Icons.save,
          isLoading: true,
          onPressed: () => calls++),
    )));
    expect(find.text('저장'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('비활성 버튼은 실행되지 않는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: AppButton(label: '완료'),
    )));
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
