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

  /// 푸들 정원 팩. 결제 연결 전에는 앱에 포함해 설정에서 바로 고를 수 있다.
  static const poodleGarden = CharacterPack(
    id: 'poodle_garden',
    characterId: 'poodle_garden',
    paletteIds: ['poodle_garden'],
    decoIds: ['plant', 'garden-daisy'],
    availability: CharacterPackAvailability.included,
  );

  /// 아무것도 고르지 않았거나, 고른 팩을 쓸 수 없을 때 돌아가는 팩.
  static const defaultPack = starlightCat;

  static const all = <CharacterPack>[starlightCat, poodleGarden];

  static CharacterPack? byId(
    String? id, {
    Iterable<CharacterPack> packs = all,
  }) {
    for (final pack in packs) {
      if (pack.id == id) return pack;
    }
    return null;
  }

  /// [pack]을 지금 고를 수 있는가 — 가지고 있고, 그릴 그림이 있어야 한다.
  ///
  /// 그림이 없는 팩을 고르게 두면 홈에 캐릭터가 사라진다. 산 팩이라도
  /// 그림이 들어올 때까지는 고를 수 없다.
  static bool isSelectable(
    CharacterPack pack,
    CharacterPackOwnership ownership,
  ) =>
      pack.hasArtwork && ownership.owns(pack);

  /// 저장된 선택값을 지금 그릴 팩으로 바꾼다.
  ///
  /// 저장값을 지우지 않고 **읽을 때마다** 판정한다. 환불로 소유가 사라지면
  /// 기본 팩으로 내려가고, 복원으로 돌아오면 저장값이 그대로 살아나 고른
  /// 팩이 다시 보인다. 없어진 팩 ID(옛 빌드의 값)도 같은 길로 기본 팩이 된다.
  static CharacterPack resolve(
    String? selectedId,
    CharacterPackOwnership ownership, {
    Iterable<CharacterPack> packs = all,
  }) {
    final pack = byId(selectedId, packs: packs);
    if (pack == null || !isSelectable(pack, ownership)) return defaultPack;
    return pack;
  }
}
