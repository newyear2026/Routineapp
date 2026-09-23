import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/screens/character_pack_detail_screen.dart';
import 'package:routine_timer/screens/character_pack_store_screen.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';
import 'package:routine_timer/widgets/ds/app_button.dart';
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
    testWidgets('그림이 없는 팩은 초상 대신 준비 중을 보여 주고 구매가 잠겨 있다', (tester) async {
      await tester.pumpWidget(localizedApp(
        home: const CharacterPackDetailScreen(packId: 'poodle_garden'),
      ));
      await tester.pump();

      // 없는 그림을 다른 캐릭터로 대신 채우지 않는다.
      expect(find.byType(AnimatedCat), findsNothing);
      expect(find.text(testL10n.characterPackArtworkPending), findsWidgets);

      // 결제 연동 전까지 버튼은 잠긴 채로 이유를 말한다.
      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.onPressed, isNull);
      expect(button.label, testL10n.characterPackOwnAction);
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
      const pack = CharacterPackCatalog.poodleGarden;
      expect(CharacterPackCatalog.isSelectable(pack, owned), isFalse);
      expect(CharacterPackCatalog.resolve(pack.id, owned).id, 'cat_starlight');
    });

    test('그림을 그릴 수 없는 팩을 넘기면 AnimatedCat은 기본 팩을 그린다', () {
      expect(
        AnimatedCat.drawablePack(CharacterPackCatalog.poodleGarden).id,
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

    testWidgets('목록은 쓰는 팩을 사용 중, 가진 다른 팩을 보유 중으로 구분한다', (tester) async {
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

    testWidgets('가진 팩이라도 그림이 없으면 쓰기 버튼이 잠겨 있다', (tester) async {
      await tester.pumpWidget(scoped(
        const CharacterPackDetailScreen(packId: 'poodle_garden'),
        current: CharacterPackCatalog.starlightCat,
        onSelect: (_) async => true,
      ));
      await tester.pump();

      await scrollToBottom(tester, find.byType(AppButton));
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.label, testL10n.characterPackUseAction);
      expect(button.onPressed, isNull);
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

class _OwnsEverything implements CharacterPackOwnership {
  const _OwnsEverything();

  @override
  bool owns(CharacterPack pack) => true;
}
