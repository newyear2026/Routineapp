import '../../domain/store/character_pack.dart';

/// 번들로 싣는 캐릭터 팩 목록.
///
/// 팩은 앱에 함께 실린다 — 승인본 6포즈가 팩당 560KB 남짓이라 내려받기
/// 구조를 만들 이유가 없고, 서버를 두지 않는다는 `PROJECT_RULES.md` 1·5장과도
/// 어긋나지 않는다.
abstract final class CharacterPackCatalog {
  /// 기본 팩. 기존 팔레트 세 종을 이 팩의 색 변형으로 흡수한다 —
  /// 무료 사용자도 만질 것이 남고, 시안의 «테마 컬러» 행과 같은 문법이 된다.
  static const starlightCat = CharacterPack(
    id: 'cat_starlight',
    characterId: 'cat_starlight',
    paletteIds: ['soft_day', 'peach_sunset', 'mint_lavender'],
    decoIds: ['plant', 'bell', 'sleeping-cat'],
    availability: CharacterPackAvailability.included,
  );

  /// 시안의 판매 팩. **그림이 아직 없다.**
  ///
  /// 없는 그림을 가짜로 채우는 대신 자리만 비워 둔다. 그림이 들어오면
  /// `characterId`와 `availability`만 바뀌고 화면은 그대로다 — 이 팩이
  /// 모델이 실제로 작동하는지 확인하는 자리다.
  static const poodleGarden = CharacterPack(
    id: 'poodle_garden',
    characterId: null,
    paletteIds: ['soft_day', 'peach_sunset', 'mint_lavender'],
    decoIds: ['plant'],
    availability: CharacterPackAvailability.comingSoon,
    productId: 'pack.poodle_garden',
  );

  /// 앱이 지금 그리고 있는 팩.
  ///
  /// 팩 선택은 아직 없다. `AnimatedCat`이 기본 팩 그림을 직접 그리므로
  /// «지금 쓰는 팩»은 기본 팩과 같다. 선택이 생기면 이 자리가
  /// `SettingsRepository`의 저장값을 읽는다.
  static const current = starlightCat;

  static const all = <CharacterPack>[starlightCat, poodleGarden];

  static CharacterPack? byId(String? id) {
    for (final pack in all) {
      if (pack.id == id) return pack;
    }
    return null;
  }
}
