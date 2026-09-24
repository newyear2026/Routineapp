import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/pack_trial.dart';
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
  final withArtwork =
      CharacterPackCatalog.all.where((pack) => pack.hasArtwork).toList();

  group('카탈로그', () {
    test('그림을 가진 팩은 모든 포즈의 그림 영역이 재어져 있다', () {
      for (final pack in withArtwork) {
        final artwork = CharacterArtwork.byCharacter[pack.characterId];
        expect(artwork, isNotNull,
            reason: '${pack.id}의 CharacterArtwork 값이 없다');
        expect(artwork!.bounds.keys.toSet(), CatPose.values.toSet());
      }
    });

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

    test('별빛 고양이와 푸들 정원 팩의 데코 아이템이 겹치지 않는다', () {
      final catDecos = CharacterPackCatalog.starlightCat.decoIds.toSet();
      final gardenDecos = CharacterPackCatalog.poodleGarden.decoIds.toSet();
      expect(catDecos, contains('plant'));
      expect(gardenDecos, contains('garden-watering-can'));
      expect(catDecos.intersection(gardenDecos), isEmpty);
    });

    test('그림을 가진 팩의 모든 포즈가 pubspec에 실려 있다', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      for (final pack in withArtwork) {
        for (final pose in CharacterPack.poseNames) {
          final asset = pack.assetFor(pose)!;
          expect(File(asset).existsSync(), isTrue, reason: '$asset 파일이 없다');
          expect(pubspec, contains('- $asset\n'),
              reason: '$asset 가 pubspec assets에 없다');
        }
      }
    });
  });

  group('목록 화면', () {
    testWidgets('모든 팩을 보여 주고 기본 팩만 사용 중으로 표시한다', (tester) async {
      await tester.pumpWidget(
        localizedApp(home: const CharacterPackStoreScreen()),
      );
      await tester.pump();

      expect(find.text(testL10n.packStarlightCatName), findsOneWidget);
      expect(find.text(testL10n.packPoodleGardenName), findsOneWidget);
      // 기본 팩 하나만 소유 상태다.
      expect(find.text(testL10n.themeInUse), findsOneWidget);
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

      await tester.tap(find.text(testL10n.packPoodleGardenName));
      await tester.pumpAndSettle();

      expect(find.text(testL10n.characterPackKicker), findsOneWidget);
      expect(find.text(testL10n.packPoodleGardenTagline), findsOneWidget);
    });
  });

  group('판매 화면', () {
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
            widget is PixelDecoration &&
            widget.asset == 'garden-watering-can'),
        findsNothing,
      );

      await scrollToBottom(tester, find.byType(CharacterPackDecoRow));
      expect(
        find.byWidgetPredicate((widget) =>
            widget is PixelDecoration &&
            widget.asset == 'garden-watering-can'),
        findsOneWidget,
      );

      // 광고로 여는 팩이고, 광고를 띄울 길이 없는 독립 화면이라 잠겨 있다.
      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
      expect(button.label, testL10n.characterPackTrialAction);
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
    expect(
      tester
          .getRect(find.byKey(const Key('home-timetable-watering-can')))
          .overlaps(tester.getRect(find.byKey(const Key('home-timetable-cat')))),
      isFalse,
    );
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

      expect(find.text(testL10n.themeInUse), findsOneWidget);
      expect(find.text(testL10n.characterPackOwned), findsOneWidget);
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
    Widget trialScoped(
      Widget home, {
      CharacterPack current = CharacterPackCatalog.starlightCat,
      CharacterPackOwnership ownership = const BundledOnlyOwnership(),
      DateTime? Function(CharacterPack)? trialEndsAt,
      Future<PackTrialOutcome> Function(CharacterPack)? onStartTrial,
    }) {
      return localizedApp(
        home: CharacterPackScope(
          current: current,
          ownership: ownership,
          onSelect: (_) async => true,
          trialEndsAt: trialEndsAt,
          onStartTrial: onStartTrial,
          child: home,
        ),
      );
    }

    testWidgets('목록에서 잠긴 팩은 광고로 체험, 체험 중인 팩은 체험 중이다', (tester) async {
      await tester.pumpWidget(trialScoped(const CharacterPackStoreScreen()));
      await tester.pump();
      expect(find.text(testL10n.characterPackTrialBadge), findsOneWidget);

      await tester.pumpWidget(trialScoped(
        const CharacterPackStoreScreen(),
        ownership: const _OwnsEverything(),
        trialEndsAt: (pack) =>
            pack.id == 'poodle_garden' ? DateTime(2026, 9, 24, 15, 20) : null,
      ));
      await tester.pump();
      expect(find.text(testL10n.characterPackTrialActive), findsOneWidget);
    });

    testWidgets('잠긴 팩은 무엇을 받는지 알리고 광고 버튼을 누르면 체험을 시작한다', (tester) async {
      final started = <String>[];
      await tester.pumpWidget(trialScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        onStartTrial: (pack) async {
          started.add(pack.id);
          return PackTrialOutcome.started;
        },
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      expect(find.text(testL10n.characterPackTrialHint), findsOneWidget);
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackTrialAction);

      await tester.tap(find.byType(AppButton));
      await tester.pump();
      await tester.pump();
      expect(started, ['poodle_garden']);
      // 성공은 화면이 바뀌는 것으로 알린다. 따로 안내하지 않는다.
      expect(find.byType(SnackBar), findsNothing);
    });

    for (final (outcome, message) in [
      (
        PackTrialOutcome.adNotCompleted,
        testL10n.characterPackTrialNotCompleted
      ),
      (
        PackTrialOutcome.dailyLimitReached,
        testL10n.characterPackTrialDailyLimit
      ),
      (PackTrialOutcome.adUnavailable, testL10n.characterPackTrialUnavailable),
      (PackTrialOutcome.failed, testL10n.characterPackSelectFailed),
    ]) {
      testWidgets('체험을 못 열면 이유를 알린다 — ${outcome.name}', (tester) async {
        await tester.pumpWidget(trialScoped(
          const CharacterPackDetailScreen(packId: 'poodle_garden'),
          onStartTrial: (_) async => outcome,
        ));
        await tester.pump();

        await scrollToBottom(tester, find.byType(AppButton));
        await tester.tap(find.byType(AppButton));
        await tester.pump();
        await tester.pump();
        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('체험 중인 팩은 사용 중 아래에 끝나는 때를 보여 준다', (tester) async {
      final end = DateTime(2026, 9, 24, 15, 20);
      await tester.pumpWidget(trialScoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        current: CharacterPackCatalog.poodleGarden,
        ownership: const _OwnsEverything(),
        trialEndsAt: (_) => end,
      ));
      await tester.pump();

      await scrollToBottom(tester, find.text(testL10n.themeInUse));
      expect(find.textContaining('15:20'), findsOneWidget);
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
