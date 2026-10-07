import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/home/home_focus_state.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/home_screen.dart';
import 'package:routine_timer/widgets/home/penguin_home_motion.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';
import 'package:provider/provider.dart';
import 'package:routine_timer/application/routine_app_controller.dart';

import 'support/localization.dart';
import 'support/routine_test_harness.dart';
import 'support/test_doubles.dart';

void main() {
  setUpRoutineTestEnvironment();

  Future<void> show(WidgetTester tester,
      {bool reduced = false,
      bool visible = true,
      HomeFocusState state = HomeFocusState.upcoming,
      String routineKey = '2026-10-06:dinner'}) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: TickerMode(
          enabled: visible,
          child: Center(
            child: SizedBox(
                width: 88,
                height: 96,
                child: PenguinHomeMotion(
                  focusState: state,
                  routineKey: routineKey,
                )),
          ),
        ),
      ),
    ));
    await tester.runAsync(() async {
      await Future.wait(PenguinHomeMotion.assets.values.map((asset) =>
          precacheImage(AssetImage(asset),
              tester.element(find.byType(PenguinHomeMotion)))));
    });
    await tester.pump();
  }

  Offset atlasOffset(WidgetTester tester) {
    final position = tester
        .widget<Positioned>(find.byKey(const Key('penguin-atlas-position')));
    return Offset(position.left!, position.top!);
  }

  testWidgets(
      'plays all eight drawings, holds neutral, and loops without scale changes',
      (tester) async {
    await show(tester);
    final first = atlasOffset(tester);
    final imageSize =
        tester.getSize(find.byKey(const Key('penguin-idle-image')));
    final positions = <Offset>{first};
    await tester.pump(const Duration(milliseconds: 2799));
    expect(atlasOffset(tester), first);
    await tester.pump(const Duration(milliseconds: 1));
    positions.add(atlasOffset(tester));
    for (var frame = 1; frame < 7; frame++) {
      await tester.pump(PenguinHomeMotion.frameDurations[frame]);
      positions.add(atlasOffset(tester));
      expect(tester.getSize(find.byKey(const Key('penguin-idle-image'))),
          imageSize);
    }
    expect(positions, hasLength(8));
    await tester.pump(PenguinHomeMotion.frameDurations[7]);
    expect(atlasOffset(tester), first);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'reduced motion, hidden tabs and background stop and reset the loop',
      (tester) async {
    await show(tester);
    final neutral = atlasOffset(tester);
    await tester.pump(const Duration(milliseconds: 2980));
    expect(atlasOffset(tester), isNot(neutral));

    await show(tester, reduced: true);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), neutral);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await show(tester);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(atlasOffset(tester), isNot(neutral));
    await show(tester, visible: false);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), neutral);

    await show(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), neutral);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 2800));
    expect(atlasOffset(tester), isNot(neutral));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
    expect(tester.takeException(), isNull);
  });

  testWidgets('active walking repeats across cycles and stable rebuilds',
      (tester) async {
    await show(tester);
    final neutral = atlasOffset(tester);
    await show(tester, state: HomeFocusState.active);
    final size = tester.getSize(find.byKey(const Key('penguin-walk-image')));
    for (var cycle = 0; cycle < 3; cycle++) {
      final positions = <Offset>{};
      for (var frame = 0; frame < 8; frame++) {
        expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
        positions.add(atlasOffset(tester));
        expect(
            tester.getSize(find.byKey(const Key('penguin-walk-image'))), size);
        // A clock refresh must not reset the running cycle.
        final beforeRebuild = atlasOffset(tester);
        await show(tester, state: HomeFocusState.active);
        expect(atlasOffset(tester), beforeRebuild);
        await tester.pump(PenguinHomeMotion.walkDurations[frame]);
      }
      expect(positions, hasLength(8));
      expect(atlasOffset(tester), neutral);
    }
    expect(find.byKey(const Key('penguin-idle-image')), findsNothing);
    await show(tester, state: HomeFocusState.snoozed);
    expect(find.byKey(const Key('penguin-walk-image')), findsNothing);
    await show(tester, state: HomeFocusState.active);
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await show(tester, state: HomeFocusState.upcoming);
    expect(find.byKey(const Key('penguin-idle-image')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'completion plays once, holds the happy frame, and never replays on entry',
      (tester) async {
    // Opening an already-active routine immediately resumes walking.
    await show(tester, state: HomeFocusState.active);
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await show(tester, state: HomeFocusState.completed);
    expect(find.byKey(const Key('penguin-complete-image')), findsOneWidget);
    final first = atlasOffset(tester);
    final positions = <Offset>{first};
    for (var frame = 0; frame < 7; frame++) {
      await tester.pump(PenguinHomeMotion.completeDurations[frame]);
      positions.add(atlasOffset(tester));
    }
    expect(positions, hasLength(8));
    final happy = atlasOffset(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), happy);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(tester, state: HomeFocusState.completed);
    expect(atlasOffset(tester), happy);
    await tester.pumpWidget(const SizedBox());
    await show(tester, state: HomeFocusState.completed);
    expect(atlasOffset(tester), happy);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Undoing completion resumes the active walking loop.
    await show(tester, state: HomeFocusState.active);
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'a new routine occurrence starts a fresh walk; skipped and day end do not celebrate',
      (tester) async {
    await show(tester, state: HomeFocusState.active);
    await show(tester,
        state: HomeFocusState.active, routineKey: '2026-10-06:reading');
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await show(tester,
        state: HomeFocusState.skipped, routineKey: '2026-10-06:reading');
    expect(find.byKey(const Key('penguin-complete-image')), findsNothing);
    await show(tester,
        state: HomeFocusState.dayDone, routineKey: '2026-10-06:reading');
    final last = atlasOffset(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), last);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(tester,
        state: HomeFocusState.active, routineKey: '2026-10-07:reading');
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('walking resumes after interruption; completion never replays',
      (tester) async {
    await show(tester);
    final neutral = atlasOffset(tester);
    final atlas = tester.getSize(find.byKey(const Key('penguin-idle-image')));
    final happy = neutral - Offset(atlas.width * .75, atlas.height * .5);
    await show(tester, state: HomeFocusState.active);
    await tester.pump(const Duration(milliseconds: 410));
    await show(tester, state: HomeFocusState.active, reduced: true);
    expect(find.byKey(const Key('penguin-walk-image')), findsNothing);
    await show(tester, state: HomeFocusState.active);
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    await tester.pump(PenguinHomeMotion.walkDurations.first);
    expect(atlasOffset(tester), isNot(neutral));
    await show(tester, state: HomeFocusState.active, visible: false);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), neutral);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await show(tester, state: HomeFocusState.active);
    await tester.pump(PenguinHomeMotion.walkDurations.first);
    expect(atlasOffset(tester), isNot(neutral));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 10));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.byKey(const Key('penguin-walk-image')), findsOneWidget);
    expect(atlasOffset(tester), neutral);
    await tester.pump(PenguinHomeMotion.walkDurations.first);
    expect(atlasOffset(tester), isNot(neutral));
    await show(tester, state: HomeFocusState.completed);
    await tester.pump(const Duration(milliseconds: 220));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    // Flutter does not paint while paused; inspect after the first resumed frame.
    await tester.pump();
    expect(atlasOffset(tester), happy);
    await tester.pump(const Duration(seconds: 10));
    expect(atlasOffset(tester), happy);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'home selects the new idle animation only for the snow-walk penguin',
      (tester) async {
    final controller = createTestRoutineController(
      now: DateTime(2026, 10, 6, 16, 51),
      routines: [
        dailyRoutine(id: 'dinner', title: '저녁 식사', startHour: 18, endHour: 19)
      ],
    );
    await controller.load();
    addTearDown(controller.dispose);
    for (final pack in [
      CharacterPackCatalog.penguinSnowWalk,
      CharacterPackCatalog.starlightCat
    ]) {
      await tester
          .pumpWidget(ChangeNotifierProvider<RoutineAppController>.value(
        value: controller,
        child: localizedApp(
            home: CharacterPackScope(
          current: pack,
          ownership: const BundledOnlyOwnership(),
          child: const HomeScreen(),
        )),
      ));
      expect(
          find.byType(PenguinHomeMotion),
          pack == CharacterPackCatalog.penguinSnowWalk
              ? findsOneWidget
              : findsNothing);
    }
    await tester.pumpWidget(const SizedBox());
  });
}
