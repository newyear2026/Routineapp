import 'character_pack.dart';

/// 출시일이 정해지면 [lastEligibleAt] 한 곳에 마지막 수령 순간을 UTC로
/// 입력한다. null인 동안에는 출시 선물이 지급되지 않는다.
abstract final class LaunchGiftCampaign {
  /// 마감일 없이 선물을 미리 받아 볼 것인가. 기본값 false.
  ///
  /// 출시 전 확인용 빌드에서만 켠다:
  ///   --dart-define=LAUNCH_GIFT_PREVIEW=true
  static const bool preview =
      bool.fromEnvironment('LAUNCH_GIFT_PREVIEW', defaultValue: false);

  static DateTime? get lastEligibleAt =>
      preview ? DateTime.utc(9999) : null;

  static bool eligible(
          {required DateTime firstLaunchAt, DateTime? lastEligibleAt}) =>
      lastEligibleAt != null && !firstLaunchAt.isAfter(lastEligibleAt);
}

class LaunchGiftOwnership implements CharacterPackOwnership {
  const LaunchGiftOwnership({required this.base, required this.eligible});

  final CharacterPackOwnership base;
  final bool eligible;

  @override
  bool owns(CharacterPack pack) =>
      base.owns(pack) ||
      (pack.availability == CharacterPackAvailability.launchGift && eligible);
}
