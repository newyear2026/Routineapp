/// 캐릭터 팩 — **파는 단위이자 고르는 단위**.
///
/// 시안의 «팩 구성 내용»(캐릭터 · 동작 · 테마 · 테마 컬러 · 데코)이 이 모델의
/// 필드 구성을 그대로 정한다.
///
/// 세 축을 따로 팔지 않는 이유는 조합의 수가 팩 수의 곱으로 늘기 때문이다.
/// 캐릭터 N개와 팔레트 M개를 따로 고르게 하면 N×M 조합을 전부 눈으로 확인해야
/// 하고, 그중 일부는 반드시 어긋난다. 팩으로 묶으면 확인은 팩당 한 번이다.
library;

enum CharacterPackAvailability {
  /// 기본 제공. 설치하면 바로 쓴다.
  included,

  /// 판매 대상.
  forSale,

  /// 보상형 광고를 끝까지 보면 `RewardedTrialOwnership.trialLength` 동안 쓴다.
  ///
  /// 광고를 켤 수 없는 플랫폼에서는 열 길이 없으므로 무료로 푼다 — 잠긴
  /// 채로 여는 방법이 없는 팩은 사용자에게 고장 난 버튼일 뿐이다.
  rewardedTrial,

  /// 자리는 정해졌고 그림이 아직 없다.
  comingSoon,
}

class CharacterPack {
  const CharacterPack({
    required this.id,
    required this.characterId,
    required this.paletteIds,
    required this.decoIds,
    required this.availability,
    this.assetVersion = 'v1',
    this.productId,
  });

  final String id;

  /// 그림이 사는 에셋 네임스페이스. 그림이 아직 없는 팩은 null이다.
  final String? characterId;

  /// 에셋 폴더의 버전 마디. 그림을 다시 그려도 옛 빌드가 깨지지 않게 남긴다.
  final String assetVersion;

  /// 팩이 제공하는 색 변형. 시안의 «테마 컬러» 행이 이 목록이다.
  final List<String> paletteIds;

  /// 팩이 제공하는 장식. 시안의 «데코 아이템 예시» 행이 이 목록이다.
  final List<String> decoIds;

  final CharacterPackAvailability availability;

  /// 스토어 상품 ID. **가격 문자열은 여기 두지 않는다** — 가격은 지역과
  /// 환율에 따라 스토어가 정하고, 앱이 들고 있으면 반드시 어긋난다.
  /// 결제가 붙으면 이 ID로 스토어에 물어 표시한다.
  final String? productId;

  /// 모든 팩이 채워야 하는 포즈. **팩이 정하는 값이 아니라 화면이 요구하는
  /// 계약이다** — 홈은 루틴 상태에 따라 포즈를 고르므로, 하나라도 비면
  /// 그 상태에서 그릴 그림이 없다.
  static const poseNames = <String>[
    'idle',
    'activity',
    'focus',
    'complete',
    'rest',
    'guide',
  ];

  bool get hasArtwork => characterId != null;

  /// 포즈 그림의 경로. 그림이 없는 팩은 null을 답한다.
  ///
  /// `AnimatedCat`이 아직 같은 경로를 직접 만들고 있다. 캐릭터 축을 풀 때
  /// 그쪽이 이 자리를 쓰게 되며, 그때까지는 테스트가 둘을 묶어 둔다.
  String? assetFor(String poseName) {
    final id = characterId;
    if (id == null) return null;
    return 'assets/characters/$id/$assetVersion/approved/$poseName.png';
  }
}

/// 팩 소유 판정.
///
/// `BUSINESS_MODEL.md` 6장이 요구하는 «화면이 `isPro`를 직접 분기하지 않는다»의
/// 경계다. 결제가 붙으면 `PurchaseRepository` 구현이 이 자리를 대신하고,
/// 화면은 그대로 둔다.
abstract interface class CharacterPackOwnership {
  bool owns(CharacterPack pack);
}

/// 결제 연동 전 기본 판정 — 기본 제공 팩만 소유로 답한다.
class BundledOnlyOwnership implements CharacterPackOwnership {
  const BundledOnlyOwnership();

  @override
  bool owns(CharacterPack pack) =>
      pack.availability == CharacterPackAvailability.included;
}
