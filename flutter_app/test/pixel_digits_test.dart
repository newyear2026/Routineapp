import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/pixel_digits.dart';

void main() {
  group('격자 글꼴', () {
    const glyphs = PixelDigitGlyphs.glyphs;

    test('모든 글자가 7줄이고 한 글자 안의 줄 폭이 같다', () {
      for (final entry in glyphs.entries) {
        expect(entry.value, hasLength(PixelDigitGlyphs.rows),
            reason: entry.key);
        expect(entry.value.map((row) => row.length).toSet(), hasLength(1),
            reason: entry.key);
      }
    });

    test('0부터 9까지 모두 서로 다른 모양이다', () {
      final digits = [for (var i = 0; i < 10; i++) glyphs['$i']!.join()];
      expect(digits.toSet(), hasLength(10));
    });

    // «13:31»이 «18:81»로 읽히던 짝. 모양이 칸 두 개 이상 달라야 한눈에 갈린다.
    for (final pair in const [('3', '8'), ('5', '6'), ('0', '8'), ('1', '7')]) {
      test('${pair.$1}과 ${pair.$2}은 여러 칸이 다르다', () {
        final a = glyphs[pair.$1]!.join();
        final b = glyphs[pair.$2]!.join();
        var diff = 0;
        for (var i = 0; i < a.length; i++) {
          if (a[i] != b[i]) diff++;
        }
        expect(diff, greaterThanOrEqualTo(4));
      });
    }

    test('3은 윗변이 평평하고 5는 왼쪽 위가 직각이다', () {
      expect(glyphs['3']!.first, '11111');
      expect(glyphs['5']!.first, '11111');
      expect(glyphs['5']![1][0], '1');
    });
  });

  testWidgets('칸 크기는 기기 픽셀에 맞고 폭 상한을 넘지 않는다', (tester) async {
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: PixelDigits('13:31', height: 30, maxWidth: 80),
      ),
    ));

    final size = tester.getSize(find.byType(CustomPaint).last);
    final columns = PixelDigitGlyphs.columnsOf('13:31');
    final cell = size.width / columns;
    expect(size.width, lessThanOrEqualTo(80));
    expect((cell * 2.75) % 1, closeTo(0, 1e-9));
    expect(size.height, closeTo(cell * PixelDigitGlyphs.rows, 1e-9));
  });

  testWidgets('스크린 리더는 숫자를 그대로 읽는다', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: PixelDigits('08:35', height: 21)),
    ));
    expect(find.bySemanticsLabel('08:35'), findsOneWidget);
    handle.dispose();
  });
}
