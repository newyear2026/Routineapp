import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routine_timer/data/local/ad_local_storage.dart';
import 'package:routine_timer/data/local/first_launch_storage.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/launch_gift.dart';

void main() {
  test('first launch is recorded before any ad request and remains stable',
      () async {
    SharedPreferences.setMockInitialValues({});
    final first = DateTime.utc(2026, 9, 29, 12);
    expect(await FirstLaunchStorage.ensure(first), first);
    expect(await FirstLaunchStorage.ensure(first.add(const Duration(days: 8))),
        first.toLocal());
  });

  test('first launch uses the existing ad timestamp and never overwrites it',
      () async {
    final original = DateTime.utc(2026, 9, 1);
    SharedPreferences.setMockInitialValues({
      'ads.first_launch_at_ms': original.millisecondsSinceEpoch,
    });

    expect(await FirstLaunchStorage.ensure(DateTime.utc(2026, 10, 1)),
        original.toLocal());
    expect(await AdLocalStorage.ensureFirstLaunchAt(DateTime.utc(2026, 12, 1)),
        original.toLocal());
  });

  test('launch gift eligibility includes testers and the cutoff instant', () {
    final cutoff = DateTime.utc(2026, 11, 30, 14, 59, 59);
    expect(
        LaunchGiftCampaign.eligible(
            firstLaunchAt: DateTime.utc(2026, 9, 1), lastEligibleAt: cutoff),
        isTrue);
    expect(
        LaunchGiftCampaign.eligible(
            firstLaunchAt: cutoff, lastEligibleAt: cutoff),
        isTrue);
    expect(
        LaunchGiftCampaign.eligible(
            firstLaunchAt: cutoff.add(const Duration(milliseconds: 1)),
            lastEligibleAt: cutoff),
        isFalse);
    expect(LaunchGiftCampaign.eligible(firstLaunchAt: DateTime.utc(2026, 9, 1)),
        isFalse);
  });

  test('gift ownership leaves the base cat and rewarded poodle rules intact',
      () {
    const base = BundledOnlyOwnership();
    const gift = LaunchGiftOwnership(base: base, eligible: true);
    const noGift = LaunchGiftOwnership(base: base, eligible: false);

    expect(gift.owns(CharacterPackCatalog.stargazerCat), isTrue);
    expect(noGift.owns(CharacterPackCatalog.stargazerCat), isFalse);
    expect(gift.owns(CharacterPackCatalog.starlightCat), isTrue);
    expect(gift.owns(CharacterPackCatalog.poodleGarden), isFalse);
  });
}
