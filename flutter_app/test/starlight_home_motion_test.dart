import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/home/starlight_home_motion.dart';

void main() {
  testWidgets('completion celebrates once, then stays still', (tester) async {
    Future<void> show(StarlightHomeMode mode) => tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 88,
                height: 96,
                child: StarlightHomeMotion(mode: mode),
              ),
            ),
          ),
        );

    CatPose pose() => tester.widget<AnimatedCat>(find.byType(AnimatedCat)).pose;

    await show(StarlightHomeMode.active);
    expect(pose(), CatPose.activity);
    await show(StarlightHomeMode.complete);
    expect(pose(), CatPose.idle); // 짧은 웅크리기
    await tester.pump(const Duration(milliseconds: 400));
    expect(pose(), CatPose.complete);
    await tester.pump(const Duration(milliseconds: 600));
    expect(pose(), CatPose.complete);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.hasScheduledFrame, isFalse);

    // 완료 상태로 새로 들어오면 축하를 다시 시작하지 않는다.
    await tester.pumpWidget(const SizedBox());
    await show(StarlightHomeMode.complete);
    expect(pose(), CatPose.complete);
    await tester.pump(const Duration(seconds: 8));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('idle and active loop, reduced motion stays still',
      (tester) async {
    Future<void> show(StarlightHomeMode mode, {bool reduced = false}) =>
        tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: Center(
                child: SizedBox(
                  width: 88,
                  height: 96,
                  child: StarlightHomeMotion(mode: mode),
                ),
              ),
            ),
          ),
        );

    double verticalOffset() => tester
        .widgetList<Transform>(find.descendant(
          of: find.byType(StarlightHomeMotion),
          matching: find.byType(Transform),
        ))
        .map((transform) => transform.transform.getTranslation().y)
        .first;

    await show(StarlightHomeMode.idle);
    await tester.pump(const Duration(milliseconds: 500));
    expect(verticalOffset(), -1);
    await show(StarlightHomeMode.active);
    await tester.runAsync(() async {
      await precacheImage(
        const ResizeImage(
          AssetImage(
              'assets/characters/cat_starlight/v1/prototype/walk_step.png'),
          width: 384,
        ),
        tester.element(find.byType(StarlightHomeMotion)),
      );
    });
    await tester.pump();
    final activeImage = find.byKey(const Key('starlight-active-image'));
    String activeAsset() {
      final image = tester.widget<Image>(activeImage).image as ResizeImage;
      return (image.imageProvider as AssetImage).assetName;
    }

    expect(activeAsset(), contains('approved/activity.png'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(verticalOffset(), lessThan(0));
    expect(activeAsset(), contains('prototype/walk_step.png'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(activeAsset(), contains('approved/activity.png'));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 250));
    expect(activeAsset(), contains('prototype/walk_step.png'));

    await show(StarlightHomeMode.active, reduced: true);
    await tester.pump(const Duration(seconds: 8));
    expect(verticalOffset(), 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
