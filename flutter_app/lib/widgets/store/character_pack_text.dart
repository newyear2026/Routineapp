import '../../domain/store/character_pack.dart';
import '../../l10n/app_localizations.dart';

/// 팩 이름과 소개 문구는 번역 파일이 갖는다.
///
/// 팩이 앱에 함께 실리므로 문구도 함께 실린다. 모델에 문자열을 담으면
/// 언어를 바꿔도 팩 이름만 한국어로 남는다.
extension CharacterPackText on CharacterPack {
  String name(AppLocalizations l10n) => switch (id) {
        'poodle_garden' => l10n.packPoodleGardenName,
        _ => l10n.packStarlightCatName,
      };

  String tagline(AppLocalizations l10n) => switch (id) {
        'poodle_garden' => l10n.packPoodleGardenTagline,
        _ => l10n.packStarlightCatTagline,
      };

  /// 가지고 있는 팩의 딱지. 기본 팩은 «기본 제공», 나머지는 «보유 중»이다.
  String ownedLabel(AppLocalizations l10n) =>
      availability == CharacterPackAvailability.included
          ? l10n.themeIncluded
          : l10n.characterPackOwned;

  /// 목록·상세에 함께 쓰는 상태 딱지 문구 — 가지지 않은 팩용.
  String statusLabel(AppLocalizations l10n) => switch (availability) {
        CharacterPackAvailability.included => l10n.themeIncluded,
        CharacterPackAvailability.forSale => l10n.characterPackOwnAction,
        CharacterPackAvailability.rewardedTrial => l10n.characterPackTrialBadge,
        CharacterPackAvailability.comingSoon => l10n.commonComingSoon,
      };
}
