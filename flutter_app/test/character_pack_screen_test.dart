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
    test('팩이 만드는 그림 경로가 AnimatedCat이 쓰는 경로와 같다', () {
      for (final pose in CatPose.values) {
        expect(
          CharacterPackCatalog.starlightCat.assetFor(pose.name),
          AnimatedCat.asset(pose),
        );
      }
    });

    test('포즈 계약이 화면이 요구하는 포즈 집합과 일치한다', () {
      expect(
        CharacterPack.poseNames.toSet(),
        CatPose.values.map((pose) => pose.name).toSet(),
      );
    });

    // AnimatedCat은 아직 'cat_starlight' 경로를 스스로 만든다. 그림을 가진
    // 둘째 팩이 생기는 순간 그 하드코딩이 조용히 틀린 캐릭터를 그리게 되므로,
    // 여기서 먼저 멈춰 캐릭터 축을 풀도록 한다.
    test('그림을 가진 팩은 아직 하나뿐이다', () {
      expect(withArtwork, hasLength(1),
          reason: '둘째 팩을 실으려면 AnimatedCat의 경로 하드코딩을 먼저 풀어야 한다');
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
}
