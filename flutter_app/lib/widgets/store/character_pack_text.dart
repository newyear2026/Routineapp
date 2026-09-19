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

  /// 목록·상세에 함께 쓰는 상태 딱지 문구.
  String statusLabel(AppLocalizations l10n) => switch (availability) {
        CharacterPackAvailability.included => l10n.themeIncluded,
        CharacterPackAvailability.forSale => l10n.characterPackOwnAction,
        CharacterPackAvailability.comingSoon => l10n.commonComingSoon,
      };
}
