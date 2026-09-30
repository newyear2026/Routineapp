import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/l10n/app_localizations.dart';
import 'package:routine_timer/theme/app_theme_preset.dart';
import 'package:routine_timer/theme/pack_skin.dart';
import 'package:routine_timer/theme/pack_skin_catalog.dart';
import 'package:routine_timer/widgets/ds/animated_cat.dart';

/// `docs/CHARACTER_PACK_SPEC.md`의 규격을 빌드에서 강제한다.
///
/// 새 팩을 카탈로그에 더하면 이 파일의 테스트가 빠진 조각을 하나씩 알려 준다.
/// 여기 적힌 규칙을 바꾸면 문서도 함께 고친다.
void main() {
  const packs = CharacterPackCatalog.all;
  final withArtwork = packs.where((pack) => pack.hasArtwork).toList();
  final pubspec = File('pubspec.yaml').readAsStringSync();

  (int, int, int) pngHeader(String path) {
    final header = ByteData.sublistView(File(path).readAsBytesSync());
    // 시그니처 8 + 길이 4 + 'IHDR' 4 다음이 폭·높이, 그 뒤 비트 깊이·색 형식이다.
    return (header.getUint32(16), header.getUint32(20), header.getUint8(25));
  }

  const rgba = 6;

  group('식별', () {
    test('팩 ID와 에셋 이름은 겹치지 않고 소문자_밑줄이다', () {
      expect(packs.map((p) => p.id).toSet(), hasLength(packs.length));
      for (final pack in packs) {
        expect(pack.id, matches(RegExp(r'^[a-z]+(_[a-z]+)+$')),
            reason: '${pack.id}: <종>_<테마> 꼴이어야 한다');
      }
    });

    test('기본 팩은 그림이 있고 기본 제공이다', () {
      const pack = CharacterPackCatalog.defaultPack;
      expect(pack.hasArtwork, isTrue);
      expect(pack.availability, CharacterPackAvailability.included);
    });

    test('모든 팩에 이름과 소개가 5개 언어로 있다', () {
      for (final locale in const ['ko', 'en', 'es', 'ja', 'pt']) {
        final l10n = lookupAppLocalizations(Locale(locale));
        final names = <String>{};
        for (final pack in packs) {
          final skin = PackSkinCatalog.byPackId[pack.id]!;
          final name = skin.name(l10n);
          expect(name.trim(), isNotEmpty, reason: '$locale ${pack.id} 이름');
          expect(skin.tagline(l10n).trim(), isNotEmpty,
              reason: '$locale ${pack.id} 소개');
          names.add(name);
        }
        expect(names, hasLength(packs.length),
            reason: '$locale: 두 팩이 같은 이름을 쓴다 — 등록표에서 복사한 줄을 확인');
      }
    });
  });

  group('그림', () {
    // 용량(130KB)은 bundled_assets_budget_test가 본다.
    test('포즈 6종이 384×384 RGBA로 approved/에 있고 pubspec에 실려 있다', () {
      for (final pack in withArtwork) {
        for (final pose in CharacterPack.poseNames) {
          final asset = pack.assetFor(pose)!;
          expect(File(asset).existsSync(), isTrue, reason: '$asset 파일이 없다');
          final (width, height, color) = pngHeader(asset);
          expect((width, height), (384, 384), reason: asset);
          expect(color, rgba, reason: '$asset 는 투명 배경(RGBA)이어야 한다');
          expect(pubspec, contains('- $asset\n'),
              reason: '$asset 가 pubspec assets에 없다');
        }
      }
    });

    test('포즈마다 그림 영역을 재 두었고 캔버스 안에 있다', () {
      for (final pack in withArtwork) {
        final artwork = CharacterArtwork.byCharacter[pack.characterId];
        expect(artwork, isNotNull, reason: '${pack.id}의 CharacterArtwork가 없다');
        expect(artwork!.bounds.keys.map((p) => p.name).toSet(),
            CharacterPack.poseNames.toSet());
        for (final entry in artwork.bounds.entries) {
          final rect = entry.value;
          expect(
            rect.left >= 0 &&
                rect.top >= 0 &&
                rect.right <= artwork.canvas &&
                rect.bottom <= artwork.canvas &&
                !rect.isEmpty,
            isTrue,
            reason: '${pack.id} ${entry.key.name}: $rect',
          );
        }
      }
    });

    test('데코는 팩끼리 겹치지 않는다', () {
      final owner = <String, String>{};
      for (final pack in packs) {
        for (final deco in pack.decoIds) {
          expect(owner[deco], isNull,
              reason: '$deco 를 ${owner[deco]}와 ${pack.id}가 함께 쓴다');
          owner[deco] = pack.id;
        }
      }
    });

    test('데코는 긴 변 384 이하 RGBA이고 pubspec에 실려 있다', () {
      for (final pack in packs) {
        expect(pack.decoIds, isNotEmpty, reason: '${pack.id}에 데코가 없다');
        for (final deco in pack.decoIds) {
          final asset = 'assets/decorations/$deco.png';
          expect(File(asset).existsSync(), isTrue, reason: '$asset 파일이 없다');
          final (width, height, color) = pngHeader(asset);
          expect(width <= 384 && height <= 384, isTrue,
              reason: '$asset ${width}x$height');
          expect(color, rgba, reason: asset);
          expect(pubspec, contains('- $asset\n'),
              reason: '$asset 가 pubspec assets에 없다');
        }
      }
    });
  });

  group('겉모습', () {
    test('카탈로그의 모든 팩에 PackSkin이 있고, 없는 팩의 것은 없다', () {
      expect(PackSkinCatalog.byPackId.keys.toSet(),
          packs.map((p) => p.id).toSet());
    });

    test('색 변형은 모두 실제 테마 프리셋이다', () {
      final presetIds = AppThemePreset.all.map((p) => p.id).toSet();
      for (final pack in packs) {
        expect(pack.paletteIds, isNotEmpty, reason: pack.id);
        for (final palette in pack.paletteIds) {
          expect(presetIds, contains(palette),
              reason: '${pack.id}의 $palette 가 AppThemePreset.all에 없다 — '
                  '없으면 조용히 soft_day로 떨어진다');
        }
      }
    });

    test('장면과 위젯은 팩이 가진 데코만 쓴다', () {
      for (final pack in packs) {
        final skin = PackSkinCatalog.byPackId[pack.id]!;
        for (final prop in skin.homeScene.props) {
          final asset = prop.asset;
          if (asset == null) continue; // 정원 잎은 장식 계열이 제공한다.
          expect(pack.decoIds, contains(asset),
              reason: '${pack.id} 홈 장면의 $asset 가 decoIds에 없다');
        }
        if (skin.widget.decor == WidgetDecor.stamp) {
          expect(pack.decoIds, contains(skin.widget.decorAsset),
              reason: '${pack.id} 위젯 도장이 decoIds에 없다');
        }
        if (skin.homeScene.backdrop case final backdrop?) {
          expect(File(backdrop).existsSync(), isTrue, reason: backdrop);
        }
      }
    });

    test('잎이 아닌 소품은 자리가 가로·세로 한쪽씩 정해져 있다', () {
      for (final pack in packs) {
        final props = PackSkinCatalog.byPackId[pack.id]!.homeScene.props;
        for (final prop in props) {
          final label = '${pack.id} ${prop.asset ?? '잎'}';
          expect((prop.left == null) != (prop.right == null), isTrue,
              reason: '$label: left·right 중 하나만');
          expect((prop.top == null) != (prop.bottom == null), isTrue,
              reason: '$label: top·bottom 중 하나만');
        }
      }
    });
  });

  group('팩 ID로 가르는 곳', () {
    final ids = packs.map((p) => p.id).toList();
    final idLiteral = RegExp("['\"](${ids.join('|')})['\"]");

    /// 팩 ID를 글자로 적어도 되는 곳. 여기 없는 파일은 [PackSkin]을 읽는다.
    const allowed = {
      // 팩 정의와 겉모습 등록표.
      'lib/data/store/character_pack_catalog.dart',
      'lib/theme/pack_skin_catalog.dart',
      // 포즈별 그림 영역. characterId로 찾는다.
      'lib/widgets/ds/animated_cat.dart',
      // 색 변형 ID가 팩 ID와 같은 이름을 쓴다.
      'lib/theme/app_theme_preset.dart',
      // 출시 선물은 특정 팩 하나를 주는 기능이다.
      'lib/data/local/launch_gift_storage.dart',
      // const 생성자 기본값이라 CharacterPackCatalog.defaultPack.id를 못 쓴다.
      'lib/widget_home/system_home_widget_payload.dart',
    };

    test('앱 코드는 팩 ID를 비교하지 않는다', () {
      final offenders = <String>[];
      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.startsWith('lib/l10n/'))) {
        if (allowed.contains(file.path)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (idLiteral.hasMatch(lines[i])) {
            offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
          }
        }
      }
      expect(offenders, isEmpty,
          reason: '팩 ID 대신 PackSkin(CharacterPackScope.skinOf)을 읽는다');
    });

    const kotlinDir = 'android/app/src/main/kotlin/com/dayround/app';
    const kotlinSkin = '$kotlinDir/RoutineWidgetSkin.kt';
    const swift = 'ios/RoutineWidgetExtension/RoutineWidgetExtension.swift';

    test('Android 위젯은 모든 팩을 RoutineWidgetSkin 한 곳에서만 가른다', () {
      final skin = File(kotlinSkin).readAsStringSync();
      for (final id in ids) {
        expect(skin, contains('"$id" ->'),
            reason: '$kotlinSkin forPack에 $id 가 없다');
      }
      for (final file in Directory(kotlinDir)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.kt') && f.path != kotlinSkin)) {
        expect(idLiteral.hasMatch(file.readAsStringSync()), isFalse,
            reason: '${file.path} 가 팩 ID를 직접 비교한다');
      }
    });

    test('iOS 위젯은 모든 팩을 WidgetPackSkin 한 곳에서만 가른다', () {
      final source = File(swift).readAsStringSync();
      final start = source.indexOf('private struct WidgetPackSkin');
      final end = source.indexOf('private struct RoutineMediumWidgetEntryView');
      expect(start, greaterThanOrEqualTo(0));
      expect(end, greaterThan(start));
      final skin = source.substring(start, end);
      final rest = source.substring(0, start) + source.substring(end);
      for (final id
          in ids.where((id) => id != CharacterPackCatalog.defaultPack.id)) {
        expect(skin, contains('case "$id":'),
            reason: 'WidgetPackSkin.forPack에 $id 가 없다');
      }
      expect(idLiteral.hasMatch(rest), isFalse,
          reason: 'WidgetPackSkin 밖에서 팩 ID를 비교한다');
      for (final match in RegExp(r'mascot: "(\w+)"').allMatches(skin)) {
        final art = 'ios/RoutineWidgetExtension/Artwork/${match[1]}.png';
        expect(File(art).existsSync(), isTrue, reason: '$art 가 없다');
      }
    });
  });
}
