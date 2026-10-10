import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/pack_ad_unlock.dart';
import 'package:routine_timer/screens/character_pack_detail_screen.dart';
import 'package:routine_timer/screens/character_pack_store_screen.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/ds/app_button.dart';
import 'package:routine_timer/widgets/ds/pixel_decoration.dart';
import 'package:routine_timer/widgets/home/home_timetable_scene.dart';
import 'package:routine_timer/widgets/store/character_pack_preview.dart';
import 'package:routine_timer/widgets/store/character_pack_scope.dart';

import 'support/localization.dart';

/// 판매 화면은 한 화면보다 길다. ListView가 지연 생성하므로 아래쪽 요소는
/// 스크롤해서 만들어 준 뒤에 본다.
Future<void> scrollToBottom(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(target, 200,
      scrollable: find.byType(Scrollable).first);
  await tester.pumpAndSettle();
}

void main() {
  group('카탈로그', () {
    // 포즈 그림·그림 영역·pubspec 등록·데코는 pack_spec_test가 모든 팩에 대해 본다.
    test('포즈 계약이 화면이 요구하는 포즈 집합과 일치한다', () {
      expect(
        CharacterPack.poseNames.toSet(),
        CatPose.values.map((pose) => pose.name).toSet(),
      );
    });

    test('기본 팩은 그림이 있고 누구나 가진다', () {
      const pack = CharacterPackCatalog.defaultPack;
      expect(pack.hasArtwork, isTrue);
      expect(const BundledOnlyOwnership().owns(pack), isTrue);
    });
  });

  group('목록 화면', () {
    testWidgets('처음에는 보유한 기본 팩만 보여 주고 스토어는 분리한다', (tester) async {
      await tester.pumpWidget(
        localizedApp(home: const CharacterPackStoreScreen()),
      );
      await tester.pump();

      expect(find.text(testL10n.packStarlightCatName), findsNWidgets(2));
      expect(find.text(testL10n.packPoodleGardenName), findsNothing);
      expect(find.text(testL10n.packPostmanRabbitName), findsNothing);
      expect(find.text(testL10n.themeInUse), findsNWidgets(2));
    });

    testWidgets('받지 못한 출시 선물은 보유 목록에 넣지 않는다', (tester) async {
      tester.view.physicalSize = const Size(430, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        localizedApp(home: const CharacterPackStoreScreen()),
      );
      await tester.pump();

      expect(find.text(testL10n.launchGiftBadge), findsNothing);
      expect(find.text(testL10n.packStargazerName), findsNothing);
    });

    testWidgets('팩을 누르면 판매 화면으로 간다', (tester) async {
      final router = GoRouter(
        initialLocation: '/character-packs',
        routes: [
          GoRoute(
            path: '/character-packs',
            builder: (_, __) => const CharacterPackStoreScreen(),
          ),
          GoRoute(
            path: '/character-packs/:id',
            builder: (_, state) => CharacterPackDetailScreen(
              packId: state.pathParameters['id']!,
            ),
          ),
        ],
      );
      await tester.pumpWidget(localizedApp(routerConfig: router));
      await tester.pump();

      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      await scrollToBottom(tester, find.text(testL10n.packPoodleGardenName));
      await tester.tap(find.text(testL10n.packPoodleGardenName));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.characterPackKicker), findsOneWidget);
      expect(find.text(testL10n.packPoodleGardenTagline), findsOneWidget);
    });
  });

  group('판매 화면', () {
    testWidgets('토끼 팩은 실제 초상과 우편 장식을 보여 준다', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: const CharacterPackDetailScreen(packId: 'rabbit_postman'),
      ));
      await tester.pump();

      expect(find.byType(AnimatedCat), findsOneWidget);
      expect(find.text(testL10n.packPostmanRabbitName), findsOneWidget);
      await scrollToBottom(tester, find.byType(CharacterPackDecoRow));
      for (final asset in CharacterPackCatalog.postmanRabbit.decoIds) {
        expect(
          find.byWidgetPredicate(
              (widget) => widget is PixelDecoration && widget.asset == asset),
          findsOneWidget,
        );
      }
    });

    testWidgets('푸들 팩은 실제 초상과 정원 장식을 보여 준다', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: const CharacterPackDetailScreen(packId: 'poodle_garden'),
      ));
      await tester.pump();

      expect(find.byType(AnimatedCat), findsOneWidget);
      expect(find.text(testL10n.characterPackArtworkPending), findsNothing);
      expect(find.byType(GardenLeaf), findsNWidgets(4));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is PixelDecoration && widget.asset == 'garden-watering-can'),
        findsNothing,
      );

      await scrollToBottom(tester, find.byType(CharacterPackDecoRow));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is PixelDecoration && widget.asset == 'garden-watering-can'),
        findsOneWidget,
      );

      // 광고로 여는 팩이고, 광고를 띄울 길이 없는 독립 화면이라 잠겨 있다.
      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
      expect(button.label, testL10n.characterPackAdUnlockAction(0, 2));
    });

    testWidgets('기본 팩은 사용 중으로 표시하고 구매 버튼을 두지 않는다', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: const CharacterPackDetailScreen(packId: 'cat_starlight'),
      ));
      await tester.pump();

      expect(find.byType(AnimatedCat), findsOneWidget);

      await scrollToBottom(tester, find.text(testL10n.themeInUse));
      expect(find.text(testL10n.themeInUse), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });

    testWidgets('구성 내용이 팩의 실제 포즈 수를 센다', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: const CharacterPackDetailScreen(packId: 'cat_starlight'),
      ));
      await tester.pump();

      expect(
        find.text(
            testL10n.characterPackSlotPoses(CharacterPack.poseNames.length)),
        findsOneWidget,
      );
    });
  });

  testWidgets('푸들 팩 홈 시간표 양옆에 잎이 보인다', (tester) async {
    await tester.pumpWidget(localizedApp(
      home: CharacterPackScope(
        current: CharacterPackCatalog.poodleGarden,
        ownership: const BundledOnlyOwnership(),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: HomeTimetableScene(
                timetableBuilder: (size) => SizedBox.square(dimension: size),
              ),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();

    final scene = tester.getRect(find.byKey(const Key('home-timetable-scene')));
    final wateringCan = tester.widget<PixelDecoration>(find.descendant(
      of: find.byKey(const Key('home-timetable-watering-can')),
      matching: find.byType(PixelDecoration),
    ));
    expect(wateringCan.asset, 'garden-watering-can');
    // 고양이는 홈 첫 카드로 옮겼다. 시간표 장면에는 없어야 두 번 그리지 않는다.
    expect(find.byKey(const Key('home-timetable-cat')), findsNothing);
    for (final key in const [
      Key('home-garden-leaf-left'),
      Key('home-garden-leaf-right'),
    ]) {
      final leaf = tester.getRect(find.byKey(key));
      expect(scene.contains(leaf.center), isTrue);
    }
  });

  group('선택 판정', () {
    const owned = _OwnsEverything();

    test('고른 것이 없거나 모르는 팩이면 기본 팩이다', () {
      expect(CharacterPackCatalog.resolve(null, owned).id, 'cat_starlight');
      expect(
          CharacterPackCatalog.resolve('gone_pack', owned).id, 'cat_starlight');
    });

    test('가지지 않은 팩은 고를 수 없고 기본 팩으로 내려간다', () {
      const custom = [CharacterPackCatalog.starlightCat, _twinCat];
      expect(
          CharacterPackCatalog.isSelectable(
              _twinCat, const BundledOnlyOwnership()),
          isFalse);
      expect(
        CharacterPackCatalog.resolve(_twinCat.id, const BundledOnlyOwnership(),
                packs: custom)
            .id,
        'cat_starlight',
      );
      expect(
        CharacterPackCatalog.resolve(_twinCat.id, owned, packs: custom).id,
        _twinCat.id,
      );
    });

    test('가진 팩이라도 그림이 없으면 고를 수 없다', () {
      const pack = _noArtwork;
      expect(CharacterPackCatalog.isSelectable(pack, owned), isFalse);
      expect(
          CharacterPackCatalog.resolve(pack.id, owned,
              packs: [CharacterPackCatalog.starlightCat, pack]).id,
          'cat_starlight');
    });

    test('그림을 그릴 수 없는 팩을 넘기면 AnimatedCat은 기본 팩을 그린다', () {
      expect(
        AnimatedCat.drawablePack(_noArtwork).id,
        'cat_starlight',
      );
      expect(AnimatedCat.drawablePack(_twinCat).id, _twinCat.id);
    });
  });

  group('팩 선택', () {
    Widget scoped(
      Widget home, {
      CharacterPack current = CharacterPackCatalog.poodleGarden,
      CharacterPackOwnership ownership = const _OwnsEverything(),
      Future<bool> Function(CharacterPack)? onSelect,
    }) {
      return localizedApp(
        home: Builder(
          builder: (context) => CharacterPackScope(
            current: current,
            ownership: ownership,
            onSelect: onSelect,
            child: home,
          ),
        ),
      );
    }

    testWidgets('목록은 쓰는 팩을 사용 중, 다른 가진 팩을 보유 중으로 구분한다', (tester) async {
      await tester.pumpWidget(scoped(
        const CharacterPackStoreScreen(),
        current: CharacterPackCatalog.starlightCat,
      ));
      await tester.pump();

      expect(find.text(testL10n.themeInUse), findsNWidgets(2));
      // 산 팩이 여럿이라 딱지 수가 아니라 카드마다 본다.
      expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(testL10n.packPoodleGardenName),
              matching: find.byType(InkWell),
            ),
            matching: find.text(testL10n.packApplyAction),
          ),
          findsOneWidget);
    });

    testWidgets('가진 팩을 쓰지 않고 있으면 쓰기 버튼을 누를 수 있다', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(scoped(
        const CharacterPackDetailScreen(packId: 'cat_starlight'),
        onSelect: (pack) async {
          selected.add(pack.id);
          return true;
        },
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackUseAction);
      expect(button.onPressed, isNotNull);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(selected, ['cat_starlight']);
    });

    testWidgets('저장에 실패하면 바꾸지 못했다고 알린다', (tester) async {
      await tester.pumpWidget(scoped(
        const CharacterPackDetailScreen(packId: 'cat_starlight'),
        onSelect: (_) async => false,
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump();

      expect(find.text(testL10n.characterPackSelectFailed), findsOneWidget);
    });

    testWidgets('푸들 팩을 설정에서 고를 수 있다', (tester) async {
      final selected = <String>[];
      await tester.pumpWidget(scoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        current: CharacterPackCatalog.starlightCat,
        onSelect: (pack) async {
          selected.add(pack.id);
          return true;
        },
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackUseAction);
      expect(button.onPressed, isNotNull);
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(selected, ['poodle_garden']);
    });

    testWidgets('바꾸는 길(onSelect)이 없는 자리에서는 쓰기 버튼이 잠겨 있다', (tester) async {
      await tester.pumpWidget(scoped(
        const CharacterPackDetailScreen(packId: 'cat_starlight'),
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
    });
  });

  group('광고로 여는 팩', () {
    Widget unlockScoped(
      Widget home, {
      CharacterPack current = CharacterPackCatalog.starlightCat,
      CharacterPackOwnership ownership = const BundledOnlyOwnership(),
      int? Function(CharacterPack)? adViews,
      Future<PackAdUnlockOutcome> Function(CharacterPack)? onWatchAd,
    }) {
      return localizedApp(
        home: CharacterPackScope(
          current: current,
          ownership: ownership,
          onSelect: (_) async => true,
          adViews: adViews,
          onWatchAd: onWatchAd,
          child: home,
        ),
      );
    }

    testWidgets('목록에서 잠긴 팩은 광고로 열기, 한 번 본 팩은 본 수를 보인다', (tester) async {
      await tester.pumpWidget(unlockScoped(const CharacterPackStoreScreen()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();
      await scrollToBottom(tester, find.text(testL10n.packPoodleGardenName));
      final poodleRow = find.ancestor(
        of: find.text(testL10n.packPoodleGardenName),
        matching: find.byType(InkWell),
      );
      expect(
          find.descendant(
            of: poodleRow,
            matching: find.text(testL10n.characterPackAdUnlockBadge),
          ),
          findsOneWidget);

      await tester.pumpWidget(unlockScoped(
        const CharacterPackStoreScreen(),
        adViews: (pack) => pack.id == 'poodle_garden' ? 1 : null,
      ));
      await tester.pump();
      expect(
          find.descendant(
            of: poodleRow,
            matching: find.text(testL10n.characterPackAdUnlockProgress(1, 2)),
          ),
          findsOneWidget);
    });

    testWidgets('펭귄 팩도 스토어의 광고 해금 목록에서 찾을 수 있다', (tester) async {
      await tester.pumpWidget(unlockScoped(const CharacterPackStoreScreen()));
      await tester.pump();
      await tester.tap(find.byKey(const Key('pack-tab-store')));
      await tester.pumpAndSettle();

      await scrollToBottom(tester, find.text(testL10n.packPenguinSnowWalkName));
      expect(find.text(testL10n.packPenguinSnowWalkName), findsOneWidget);
      final penguinRow = find.ancestor(
        of: find.text(testL10n.packPenguinSnowWalkName),
        matching: find.byType(InkWell),
      );
      expect(
          find.descendant(
            of: penguinRow,
            matching: find.text(testL10n.characterPackAdUnlockBadge),
          ),
          findsOneWidget);
    });

    testWidgets('광고로 연 팩은 목록에서 다른 산 팩과 똑같이 보유 중이다', (tester) async {
      await tester.pumpWidget(unlockScoped(
        const CharacterPackStoreScreen(),
        ownership: const _OwnsEverything(),
      ));
      await tester.pump();
      expect(
          find.descendant(
            of: find.ancestor(
              of: find.text(testL10n.packPoodleGardenName),
              matching: find.byType(InkWell),
            ),
            matching: find.text(testL10n.packApplyAction),
          ),
          findsOneWidget);
      expect(find.text(testL10n.characterPackAdUnlockBadge), findsNothing);
    });

    testWidgets('잠긴 팩은 몇 번 봐야 하는지 알리고 광고 버튼을 누르면 센다', (tester) async {
      final watched = <String>[];
      await tester.pumpWidget(unlockScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        onWatchAd: (pack) async {
          watched.add(pack.id);
          return PackAdUnlockOutcome.unlocked;
        },
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      expect(find.text(testL10n.characterPackAdUnlockHint(2)), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackAdUnlockAction(0, 2));

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump();
      expect(watched, ['poodle_garden']);
      // 다 열리면 화면이 바뀌는 것으로 알린다. 따로 안내하지 않는다.
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('한 번 본 팩은 버튼에 본 수를 보이고, 반만 채우면 남은 수를 알린다', (tester) async {
      await tester.pumpWidget(unlockScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        adViews: (_) => 0,
        onWatchAd: (_) async => PackAdUnlockOutcome.progressed,
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump();
      expect(find.text(testL10n.characterPackAdUnlockProgressed(1)),
          findsOneWidget);

      await tester.pumpWidget(unlockScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        adViews: (_) => 1,
        onWatchAd: (_) async => PackAdUnlockOutcome.unlocked,
      ));
      await tester.pump();
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackAdUnlockAction(1, 2));
    });

    for (final (outcome, message) in [
      (
        PackAdUnlockOutcome.adNotCompleted,
        testL10n.characterPackAdUnlockNotCompleted
      ),
      (
        PackAdUnlockOutcome.adUnavailable,
        testL10n.characterPackAdUnlockUnavailable
      ),
      (PackAdUnlockOutcome.failed, testL10n.characterPackSelectFailed),
    ]) {
      testWidgets('광고를 세지 못하면 이유를 알린다 — ${outcome.name}', (tester) async {
        await tester.pumpWidget(unlockScoped(
          const CharacterPackDetailScreen(packId: 'poodle_garden'),
          onWatchAd: (_) async => outcome,
        ));
        await tester.pump();

        await scrollToBottom(tester, find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump();
        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('광고로 연 팩은 끝나는 때 없이 사용 중으로만 보인다', (tester) async {
      await tester.pumpWidget(unlockScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        current: CharacterPackCatalog.poodleGarden,
        ownership: const _OwnsEverything(),
      ));
      await tester.pump();

      await scrollToBottom(tester, find.text(testL10n.themeInUse));
      expect(find.text(testL10n.themeInUse), findsOneWidget);
      expect(find.byType(AppButton), findsNothing);
    });
  });
}

/// 테스트용 둘째 팩 — 기본 팩의 그림을 빌려 쓴다.
const _twinCat = CharacterPack(
  id: 'cat_twin',
  characterId: 'cat_starlight',
  paletteIds: ['soft_day'],
  decoIds: ['plant'],
  availability: CharacterPackAvailability.forSale,
  productId: 'pack.cat_twin',
);

const _noArtwork = CharacterPack(
  id: 'no_artwork',
  characterId: null,
  paletteIds: [],
  decoIds: [],
  availability: CharacterPackAvailability.included,
);

class _OwnsEverything implements CharacterPackOwnership {
  const _OwnsEverything();

  @override
  bool owns(CharacterPack pack) => true;
}
