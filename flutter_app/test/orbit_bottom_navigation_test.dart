import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/orbit_bottom_navigation.dart';
import 'package:routine_timer/widgets/ds/pixel_icon.dart';

import 'support/localization.dart';

void main() {
  testWidgets('하단 탭은 전용 픽셀 아이콘 네 개와 기존 이동 동작을 유지한다', (tester) async {
    int? tappedIndex;
    await tester.pumpWidget(localizedApp(
      home: Scaffold(
        bottomNavigationBar: OrbitBottomNavigation(
          currentIndex: 1,
          onHome: () => tappedIndex = 0,
          onProgress: () => tappedIndex = 1,
          onRoutines: () => tappedIndex = 2,
          onSettings: () => tappedIndex = 3,
        ),
      ),
    ));

    expect(
      tester
          .widgetList<PixelIcon>(find.byType(PixelIcon))
          .map((icon) => icon.glyph),
      [
        PixelGlyph.navHome,
        PixelGlyph.navProgress,
        PixelGlyph.navRoutines,
        PixelGlyph.navSettings,
      ],
    );

    for (final (index, label) in ['홈', '진행', '루틴', '설정'].indexed) {
      await tester.tap(find.text(label));
      expect(tappedIndex, index);
    }
  });
}
