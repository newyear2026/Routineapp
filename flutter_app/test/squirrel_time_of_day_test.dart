import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/home/squirrel_time_of_day.dart';

void main() {
  test('다람쥐 숲은 05·11·17·20시에 장면을 바꾼다', () {
    expect(SquirrelTimeOfDay.fromHour(4), SquirrelTimeOfDay.night);
    expect(SquirrelTimeOfDay.fromHour(5), SquirrelTimeOfDay.morning);
    expect(SquirrelTimeOfDay.fromHour(10), SquirrelTimeOfDay.morning);
    expect(SquirrelTimeOfDay.fromHour(11), SquirrelTimeOfDay.day);
    expect(SquirrelTimeOfDay.fromHour(16), SquirrelTimeOfDay.day);
    expect(SquirrelTimeOfDay.fromHour(17), SquirrelTimeOfDay.sunset);
    expect(SquirrelTimeOfDay.fromHour(19), SquirrelTimeOfDay.sunset);
    expect(SquirrelTimeOfDay.fromHour(20), SquirrelTimeOfDay.night);
    expect(SquirrelTimeOfDay.fromHour(23), SquirrelTimeOfDay.night);
  });

  testWidgets('숲의 움직임은 시스템 애니메이션 축소를 따른다', (tester) async {
    Widget scene({required bool disableAnimations}) => MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData()
                  .copyWith(disableAnimations: disableAnimations),
              child: const SizedBox(
                width: 390,
                height: 250,
                child: SquirrelAtmosphere(
                  timeOfDay: SquirrelTimeOfDay.night,
                  area: SquirrelAtmosphereArea.header,
                ),
              ),
            ),
          ),
        );

    await tester.pumpWidget(scene(disableAnimations: false));
    expect(tester.hasRunningAnimations, isTrue);

    await tester.pumpWidget(scene(disableAnimations: true));
    expect(tester.hasRunningAnimations, isFalse);
  });
}
