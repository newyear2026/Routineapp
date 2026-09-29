import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/app_pixel_switch.dart';

void main() {
  testWidgets('사각 토글은 넓은 터치 영역과 키보드로 값을 바꾼다', (tester) async {
    var value = false;
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (context, setState) => AppPixelSwitch(
          label: '알림',
          value: value,
          onChanged: (next) => setState(() {
                value = next;
                calls++;
              })),
    ))));
    final target = find.byType(AppPixelSwitch);
    expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
    await tester.tapAt(tester.getTopLeft(target) + const Offset(5, 3));
    await tester.pumpAndSettle();
    expect(value, isTrue);
    expect(calls, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, isFalse);
    expect(calls, 2);
  });
  testWidgets('비활성 토글은 저장된 상태를 표시하고 조작하지 않는다', (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
      body: AppPixelSwitch(label: '알림', value: true, onChanged: null),
    )));
    await tester.tap(find.byType(AppPixelSwitch));
    await tester.pumpAndSettle();
    expect(tester.widget<AppPixelSwitch>(find.byType(AppPixelSwitch)).value,
        isTrue);
    expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
  });
}
