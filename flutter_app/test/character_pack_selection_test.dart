import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/rewarded_ad_service.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/settings_repository.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/ads/ad_slot.dart';
import 'package:routine_timer/domain/models/app_settings.dart';
import 'package:routine_timer/domain/models/watch_state.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/store/character_pack.dart';
import 'package:routine_timer/domain/store/pack_ad_unlock.dart';

import 'support/test_doubles.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidgetChannel = MethodChannel('home_widget');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, (call) async => true);
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidgetChannel, null);
  });

  const packs = [CharacterPackCatalog.starlightCat, _twinCat];

  Future<RoutineAppController> loadController(
    _MemorySettingsRepository settings, {
    CharacterPackOwnership ownership = const _Owns({'cat_twin'}),
    List<CharacterPack> characterPacks = packs,
    bool rewardedPackUnlocks = false,
    PackAdUnlockStore? unlockStore,
    Future<RewardedAdOutcome> Function(AdSlot slot)? showRewardedAd,
    DateTime Function()? now,
    DateTime? launchGiftDeadline,
  }) async {
    final controller = RoutineAppController(
      dataService: RoutineDataService(
        routineRepository: MemoryRoutineRepository(const []),
        logRepository: MemoryLogRepository(),
      ),
      notificationService: RoutineNotificationService(
        exactAlarmsAllowed: () async => false,
        gateway: NoopNotificationGateway(),
        preferencesLoader: () async =>
            NotificationPreferences.firstLaunchDefaults,
      ),
      settingsRepository: settings,
      packOwnership: ownership,
      packAdUnlockStore: unlockStore ?? _MemoryUnlockStore(),
      rewardedPackUnlocks: rewardedPackUnlocks,
      showRewardedAd: showRewardedAd ?? (_) async => RewardedAdOutcome.earned,
      characterPacks: characterPacks,
      nowProvider: now ?? () => DateTime(2026, 9, 22, 10, 0),
      launchGiftDeadline: launchGiftDeadline,
      clockAutoRefreshEnabled: false,
    );
    await controller.load();
    return controller;
  }

  test('처음에는 기본 팩을 쓴다', () async {
    final controller = await loadController(_MemorySettingsRepository());
    expect(controller.currentPack.id, 'cat_starlight');
  });

  test('고른 팩이 저장되고 다시 열어도 남아 있다', () async {
    final settings = _MemorySettingsRepository();
    final controller = await loadController(settings);

    expect(await controller.selectCharacterPack(_twinCat), isTrue);
    expect(controller.currentPack.id, 'cat_twin');
    expect(settings.saved.characterPackId, 'cat_twin');

    final reopened = await loadController(settings);
    expect(reopened.currentPack.id, 'cat_twin');
  });

  test('광고를 켤 수 없는 플랫폼에서는 푸들 정원 팩을 바로 고르고 재실행 후 유지된다', () async {
    final settings = _MemorySettingsRepository();
    final controller = await loadController(settings,
        characterPacks: CharacterPackCatalog.all);

    expect(
        await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
        isTrue);
    expect(controller.currentPack.id, 'poodle_garden');
    expect(controller.currentThemePreset.id, 'poodle_garden');
    expect(settings.saved.characterPackId, 'poodle_garden');

    final reopened = await loadController(settings,
        characterPacks: CharacterPackCatalog.all);
    expect(reopened.currentPack.id, 'poodle_garden');
    expect(reopened.currentThemePreset.id, 'poodle_garden');
  });

  test('가지지 않은 팩은 거절하고 저장하지 않는다', () async {
    final settings = _MemorySettingsRepository();
    final controller =
        await loadController(settings, ownership: const _Owns({}));

    expect(await controller.selectCharacterPack(_twinCat), isFalse);
    expect(controller.currentPack.id, 'cat_starlight');
    expect(settings.saveCount, 0);
  });

  test('목록에 없는 팩은 거절한다', () async {
    final controller = await loadController(_MemorySettingsRepository(),
        ownership: const _Owns({'cat_twin', 'poodle_garden'}));

    expect(
      await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
      isFalse,
    );
    expect(controller.currentPack.id, 'cat_starlight');
  });

  test('저장이 실패하면 고르기 전 팩으로 되돌린다', () async {
    final settings = _MemorySettingsRepository()..failSaves = true;
    final controller = await loadController(settings);

    expect(await controller.selectCharacterPack(_twinCat), isFalse);
    expect(controller.currentPack.id, 'cat_starlight');
  });

  test('소유가 사라지면 기본 팩으로 내려가고, 돌아오면 고른 팩이 살아난다', () async {
    final settings = _MemorySettingsRepository();
    final first = await loadController(settings);
    await first.selectCharacterPack(_twinCat);

    // 환불 — 저장값은 그대로 두고 판정만 바뀐다.
    final refunded = await loadController(settings, ownership: const _Owns({}));
    expect(refunded.currentPack.id, 'cat_starlight');
    expect(settings.saved.characterPackId, 'cat_twin');

    // 복원
    final restored = await loadController(settings);
    expect(restored.currentPack.id, 'cat_twin');
  });

  group('광고로 여는 팩', () {
    test('광고를 보지 않으면 고를 수 없다', () async {
      final settings = _MemorySettingsRepository();
      final controller = await loadController(settings,
          characterPacks: CharacterPackCatalog.all, rewardedPackUnlocks: true);

      expect(
        await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
        isFalse,
      );
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), 0);
      expect(settings.saveCount, 0);
    });

    test('두 번째 광고를 끝까지 보면 영구히 열리고 바로 적용된다', () async {
      var clock = DateTime(2026, 9, 22, 10, 0);
      final settings = _MemorySettingsRepository();
      final store = _MemoryUnlockStore();
      final shown = <AdSlot>[];
      final controller = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        unlockStore: store,
        now: () => clock,
        showRewardedAd: (slot) async {
          shown.add(slot);
          return RewardedAdOutcome.earned;
        },
      );

      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.progressed,
      );
      expect(controller.currentPack.id, 'cat_starlight');
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), 1);
      expect(store.views, {'poodle_garden': 1});
      expect(settings.saveCount, 0);

      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.unlocked,
      );
      expect(shown, [AdSlot.packUnlockReward, AdSlot.packUnlockReward]);
      expect(controller.currentPack.id, 'poodle_garden');
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), isNull);

      // 끝나는 때가 없다.
      clock = DateTime(2027, 9, 22, 10, 0);
      expect(controller.currentPack.id, 'poodle_garden');
    });

    test('펭귄 팩은 푸들과 별도로 광고 두 번을 보면 영구히 열린다', () async {
      final settings = _MemorySettingsRepository();
      final store = _MemoryUnlockStore();
      final controller = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        unlockStore: store,
      );
      const penguin = CharacterPackCatalog.penguinSnowWalk;

      expect(await controller.selectCharacterPack(penguin), isFalse);
      expect(await controller.watchAdForPackUnlock(penguin),
          PackAdUnlockOutcome.progressed);
      expect(controller.packAdViews(penguin), 1);
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), 0);
      expect(await controller.watchAdForPackUnlock(penguin),
          PackAdUnlockOutcome.unlocked);
      expect(controller.currentPack.id, penguin.id);
      expect(controller.currentThemePreset.id, penguin.id);
      expect(store.views, {penguin.id: 2});

      final reopened = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        unlockStore: store,
      );
      expect(reopened.currentPack.id, penguin.id);
      expect(reopened.packAdViews(penguin), isNull);
      expect(reopened.packAdViews(CharacterPackCatalog.poodleGarden), 0);
    });

    test('본 수는 앱을 다시 켜도 남고, 나눠 봐도 이어진다', () async {
      final settings = _MemorySettingsRepository();
      final store = _MemoryUnlockStore();
      final first = await loadController(settings,
          characterPacks: CharacterPackCatalog.all,
          rewardedPackUnlocks: true,
          unlockStore: store);
      await first.watchAdForPackUnlock(CharacterPackCatalog.poodleGarden);

      final second = await loadController(settings,
          characterPacks: CharacterPackCatalog.all,
          rewardedPackUnlocks: true,
          unlockStore: store);
      expect(second.packAdViews(CharacterPackCatalog.poodleGarden), 1);
      expect(
        await second.watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.unlocked,
      );

      final third = await loadController(settings,
          characterPacks: CharacterPackCatalog.all,
          rewardedPackUnlocks: true,
          unlockStore: store);
      expect(third.currentPack.id, 'poodle_garden');
    });

    test('광고를 도중에 닫으면 세지 않는다', () async {
      final settings = _MemorySettingsRepository();
      final store = _MemoryUnlockStore();
      final controller = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        unlockStore: store,
        showRewardedAd: (_) async => RewardedAdOutcome.dismissed,
      );

      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.adNotCompleted,
      );
      expect(controller.currentPack.id, 'cat_starlight');
      expect(store.views, isEmpty);
      expect(settings.saveCount, 0);
    });

    test('하루 상한과 로드 실패를 구분해 돌려준다', () async {
      for (final (ad, expected) in [
        (
          RewardedAdOutcome.dailyCapReached,
          PackAdUnlockOutcome.dailyLimitReached
        ),
        (RewardedAdOutcome.unavailable, PackAdUnlockOutcome.adUnavailable),
      ]) {
        final controller = await loadController(
          _MemorySettingsRepository(),
          characterPacks: CharacterPackCatalog.all,
          rewardedPackUnlocks: true,
          showRewardedAd: (_) async => ad,
        );
        expect(
          await controller
              .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
          expected,
        );
      }
    });

    test('저장이 실패해도 광고를 본 이번 실행에는 센 수를 쥐고 있다', () async {
      final controller = await loadController(
        _MemorySettingsRepository(),
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        unlockStore: _MemoryUnlockStore()..failSaves = true,
      );

      await controller.watchAdForPackUnlock(CharacterPackCatalog.poodleGarden);
      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.unlocked,
      );
      expect(controller.currentPack.id, 'poodle_garden');
    });

    test('광고를 켤 수 없는 플랫폼에서는 광고 없이 풀려 있다', () async {
      var shown = 0;
      final controller = await loadController(
        _MemorySettingsRepository(),
        characterPacks: CharacterPackCatalog.all,
        showRewardedAd: (_) async {
          shown++;
          return RewardedAdOutcome.earned;
        },
      );

      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.failed,
      );
      expect(shown, 0);
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), isNull);
      expect(
        await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
        isTrue,
      );
    });

    test('산 팩은 광고를 셀 것이 없다', () async {
      var shown = 0;
      final controller = await loadController(
        _MemorySettingsRepository(),
        ownership: const _Owns({'poodle_garden'}),
        characterPacks: CharacterPackCatalog.all,
        rewardedPackUnlocks: true,
        showRewardedAd: (_) async {
          shown++;
          return RewardedAdOutcome.earned;
        },
      );

      expect(
        await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
        isTrue,
      );
      expect(
        await controller
            .watchAdForPackUnlock(CharacterPackCatalog.poodleGarden),
        PackAdUnlockOutcome.failed,
      );
      expect(controller.packAdViews(CharacterPackCatalog.poodleGarden), isNull);
      expect(shown, 0);
    });
  });

  test('출시 전에 처음 연 사용자는 한정 팩을 골라도 기본 팩 규칙이 유지된다', () async {
    SharedPreferences.setMockInitialValues({
      'ads.first_launch_at_ms': DateTime.utc(2026, 9, 1).millisecondsSinceEpoch,
    });
    final settings = _MemorySettingsRepository();
    final controller = await loadController(
      settings,
      characterPacks: CharacterPackCatalog.all,
      launchGiftDeadline: DateTime.utc(2026, 11, 30, 14, 59, 59),
    );

    expect(controller.shouldShowLaunchGift, isTrue);
    expect(controller.packOwnership.owns(CharacterPackCatalog.stargazerCat),
        isTrue);
    expect(
        await controller.selectCharacterPack(CharacterPackCatalog.stargazerCat),
        isTrue);
    expect(controller.currentPack.id, 'cat_stargazer');
    expect(controller.currentThemePreset.id, 'stargazer');
  });

  test('AppSettings는 고른 팩을 JSON으로 오간다', () {
    const settings = AppSettings(characterPackId: 'cat_twin');
    expect(
      AppSettings.fromJson(settings.toJson()).characterPackId,
      'cat_twin',
    );
    expect(AppSettings.fromJson(const {}).characterPackId, isNull);
  });
}

/// 기본 팩의 그림을 빌려 쓰는 둘째 팩. 그림을 가진 판매 팩이 아직 없어서다.
const _twinCat = CharacterPack(
  id: 'cat_twin',
  characterId: 'cat_starlight',
  paletteIds: ['soft_day'],
  decoIds: ['plant'],
  availability: CharacterPackAvailability.forSale,
  productId: 'pack.cat_twin',
);

/// 기본 제공 팩과 [ids]에 든 팩을 가진 것으로 답한다.
class _Owns implements CharacterPackOwnership {
  const _Owns(this.ids);

  final Set<String> ids;

  @override
  bool owns(CharacterPack pack) =>
      pack.availability == CharacterPackAvailability.included ||
      ids.contains(pack.id);
}

class _MemorySettingsRepository implements SettingsRepository {
  AppSettings saved = const AppSettings();
  int saveCount = 0;
  bool failSaves = false;

  @override
  Future<AppSettings> loadAppSettings() async => saved;

  @override
  Future<void> saveAppSettings(AppSettings settings) async {
    if (failSaves) throw StateError('storage unavailable');
    saveCount++;
    saved = settings;
  }

  @override
  Future<WatchState> loadWatchState() async => const WatchState();

  @override
  Future<void> saveWatchState(WatchState state) async {}

  @override
  Future<NotificationPreferences> loadNotificationPreferences() async =>
      NotificationPreferences.firstLaunchDefaults;

  @override
  Future<void> saveNotificationPreferences(
    NotificationPreferences preferences,
  ) async {}
}

class _MemoryUnlockStore implements PackAdUnlockStore {
  final Map<String, int> views = {};
  bool failSaves = false;

  @override
  Future<Map<String, int>> loadAdViews() async => Map.of(views);

  @override
  Future<void> saveAdViews(String packId, int count) async {
    if (failSaves) throw StateError('save failed');
    views[packId] = count;
  }
}
