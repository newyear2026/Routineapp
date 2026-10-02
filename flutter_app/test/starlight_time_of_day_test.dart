import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/home/starlight_time_of_day.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('하늘은 05·11·17·20시에 다음 시간대로 바뀐다', () {
    expect(StarlightTimeOfDay.fromHour(4), StarlightTimeOfDay.night);
    expect(StarlightTimeOfDay.fromHour(5), StarlightTimeOfDay.morning);
    expect(StarlightTimeOfDay.fromHour(10), StarlightTimeOfDay.morning);
    expect(StarlightTimeOfDay.fromHour(11), StarlightTimeOfDay.day);
    expect(StarlightTimeOfDay.fromHour(16), StarlightTimeOfDay.day);
    expect(StarlightTimeOfDay.fromHour(17), StarlightTimeOfDay.sunset);
    expect(StarlightTimeOfDay.fromHour(19), StarlightTimeOfDay.sunset);
    expect(StarlightTimeOfDay.fromHour(20), StarlightTimeOfDay.night);
    expect(StarlightTimeOfDay.fromHour(0), StarlightTimeOfDay.night);
    expect(StarlightTimeOfDay.night.hasLightHeaderText, isTrue);
  });

  test('네 시간대의 배경 이미지가 모두 앱 자산에 포함된다', () async {
    for (final timeOfDay in StarlightTimeOfDay.values) {
      expect(timeOfDay.cardAsset, isNot(timeOfDay.headerAsset));
      for (final asset in [timeOfDay.headerAsset, timeOfDay.cardAsset]) {
        final image = await rootBundle.load(asset);
        expect(image.lengthInBytes, greaterThan(0));
      }
    }
  });

  testWidgets('상단 하늘 이미지는 화면 양쪽 끝까지 채운다', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StarlightSkyBackdrop(
            timeOfDay: StarlightTimeOfDay.day,
            animate: false,
          ),
        ),
      ),
    );

    final sky = tester.getRect(find.byType(Image));
    expect(sky.left, 0);
    expect(sky.right, 390);
  });
}
