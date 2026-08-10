import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/theme/routine_palette.dart';

void main() {
  test('이전 파스텔 색상을 선명한 공통 팔레트로 변환한다', () {
    expect(
      RoutinePalette.normalizeValue(0xFFFFE4E9),
      RoutinePalette.coralValue,
    );
    expect(
      RoutinePalette.normalizeValue(0xFFE8DDFA),
      RoutinePalette.lavenderValue,
    );
    expect(
      RoutinePalette.normalizeValue(0xFFD4E4FF),
      RoutinePalette.blueValue,
    );
  });

  test('새 팔레트의 8가지 색은 서로 구분된다', () {
    expect(RoutinePalette.colors, hasLength(8));
    expect(RoutinePalette.colors.toSet(), hasLength(8));
  });

  test('이전 팔레트에 없던 색은 변경하지 않는다', () {
    expect(RoutinePalette.normalizeValue(0xFF123456), 0xFF123456);
  });
}
