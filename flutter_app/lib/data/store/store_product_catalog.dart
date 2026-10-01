import '../../domain/store/character_pack.dart';
import 'character_pack_catalog.dart';

/// Play에서 파는 상품과, 상품마다 지급하는 권리.
///
/// 모두 비소모성이다. 한 번 사면 Play 계정에 남아, 계정 없이도 재설치나
/// 기기 변경 뒤에 복원된다. **상품 ID는 Play Console에 한 번 만들면 다시 쓸
/// 수 없다** — 바꾸지 말고, 등록 목록은 `docs/STORE_PRODUCTS.md`에 있다.
abstract final class StoreProductCatalog {
  /// 판매 팩 전부 + 광고로 여는 팩 + 광고 제거.
  ///
  /// 출시 선물 팩은 넣지 않는다. 기간 안에 시작한 사람만 갖는 것이 선물의
  /// 뜻이라, 돈으로 살 수 있게 되면 한정이 아니게 된다.
  static const bundle = 'loopet.supporter.bundle';

  /// 홈·진행 화면의 네이티브 광고를 끄는 권리. 팩이 아니라 번들에만 딸려 온다.
  /// 보상형 광고는 사용자가 눌러야 시작하므로 끄지 않는다.
  static const adFree = 'ads.removed';

  /// 상품 ID → 지급할 권리(팩 ID와 [adFree]).
  static Map<String, Set<String>> grantsFor(Iterable<CharacterPack> packs) => {
        for (final pack in packs)
          if (pack.availability == CharacterPackAvailability.forSale &&
              pack.productId != null)
            pack.productId!: {pack.id},
        bundle: {
          for (final pack in packs)
            if (_inBundle(pack)) pack.id,
          adFree,
        },
      };

  static final grants = grantsFor(CharacterPackCatalog.all);

  static Set<String> get productIds => grants.keys.toSet();

  static bool _inBundle(CharacterPack pack) =>
      pack.availability == CharacterPackAvailability.forSale ||
      pack.availability == CharacterPackAvailability.rewardedUnlock;
}
