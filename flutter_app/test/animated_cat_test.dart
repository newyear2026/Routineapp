import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';

void main() {
  testWidgets('hidden and background cats stop requesting frames and resume',
      (tester) async {
    Future<void> show(bool enabled) async {
      await tester.pumpWidget(MaterialApp(
          home: TickerMode(
              enabled: enabled,
              child: const SizedBox(
                  width: 100,
                  height: 100,
                  child: AnimatedCat(pose: CatPose.activity)))));
      await tester.pumpAndSettle();
    }

    await show(true);
    await show(false);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
      'all poses keep a fixed box and bottom anchor; reduced motion stops',
      (tester) async {
    Future<void> show(CatPose pose, {bool reduced = false}) async {
      await tester.pumpWidget(MaterialApp(
          home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: Center(
            child: SizedBox(
                width: 100, height: 70, child: AnimatedCat(pose: pose))),
      )));
      await tester.pumpAndSettle();
    }

    await show(CatPose.idle);
    final bounds = tester.getRect(find.byType(AnimatedCat));
    for (final pose in CatPose.values) {
      await show(pose);
      expect(tester.getRect(find.byType(AnimatedCat)), bounds);
      expect(tester.takeException(), isNull);
    }
    await show(CatPose.rest, reduced: true);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });
}
