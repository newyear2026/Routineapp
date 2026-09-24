import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
import 'package:routine_timer/domain/store/pack_trial.dart';

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
    bool rewardedPackTrials = false,
    PackTrialStore? trialStore,
    Future<RewardedAdOutcome> Function(AdSlot slot)? showRewardedAd,
    DateTime Function()? now,
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
      packTrialStore: trialStore ?? _MemoryTrialStore(),
      rewardedPackTrials: rewardedPackTrials,
      showRewardedAd: showRewardedAd ?? (_) async => RewardedAdOutcome.earned,
      characterPacks: characterPacks,
      nowProvider: now ?? () => DateTime(2026, 9, 22, 10, 0),
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
          characterPacks: CharacterPackCatalog.all, rewardedPackTrials: true);

      expect(
        await controller.selectCharacterPack(CharacterPackCatalog.poodleGarden),
        isFalse,
      );
      expect(settings.saveCount, 0);
    });

    test('광고를 끝까지 보면 바로 적용되고 24시간 뒤 기본 팩으로 돌아간다', () async {
      var clock = DateTime(2026, 9, 22, 10, 0);
      final settings = _MemorySettingsRepository();
      final shown = <AdSlot>[];
      final controller = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackTrials: true,
        now: () => clock,
        showRewardedAd: (slot) async {
          shown.add(slot);
          return RewardedAdOutcome.earned;
        },
      );

      expect(
        await controller.watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
        PackTrialOutcome.started,
      );
      expect(shown, [AdSlot.packTrialReward]);
      expect(controller.currentPack.id, 'poodle_garden');
      expect(
        controller.packTrialEndsAt(CharacterPackCatalog.poodleGarden),
        DateTime(2026, 9, 23, 10, 0),
      );

      clock = DateTime(2026, 9, 23, 9, 59);
      expect(controller.currentPack.id, 'poodle_garden');

      clock = DateTime(2026, 9, 23, 10, 0);
      expect(controller.currentPack.id, 'cat_starlight');
      expect(controller.currentThemePreset.id, isNot('poodle_garden'));
      expect(controller.packTrialEndsAt(CharacterPackCatalog.poodleGarden),
          isNull);
      // 저장값은 남는다 — 다시 광고를 보면 고른 팩이 그대로 살아난다.
      expect(settings.saved.characterPackId, 'poodle_garden');
    });

    test('체험은 앱을 다시 켜도 남는다', () async {
      final settings = _MemorySettingsRepository();
      final store = _MemoryTrialStore();
      final first = await loadController(settings,
          characterPacks: CharacterPackCatalog.all,
          rewardedPackTrials: true,
          trialStore: store);
      await first.watchAdForPackTrial(CharacterPackCatalog.poodleGarden);

      final reopened = await loadController(settings,
          characterPacks: CharacterPackCatalog.all,
          rewardedPackTrials: true,
          trialStore: store);
      expect(reopened.currentPack.id, 'poodle_garden');
    });

    test('광고를 도중에 닫으면 열리지 않는다', () async {
      final settings = _MemorySettingsRepository();
      final store = _MemoryTrialStore();
      final controller = await loadController(
        settings,
        characterPacks: CharacterPackCatalog.all,
        rewardedPackTrials: true,
        trialStore: store,
        showRewardedAd: (_) async => RewardedAdOutcome.dismissed,
      );

      expect(
        await controller.watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
        PackTrialOutcome.adNotCompleted,
      );
      expect(controller.currentPack.id, 'cat_starlight');
      expect(store.ends, isEmpty);
      expect(settings.saveCount, 0);
    });

    test('하루 상한과 로드 실패를 구분해 돌려준다', () async {
      for (final (ad, expected) in [
        (RewardedAdOutcome.dailyCapReached, PackTrialOutcome.dailyLimitReached),
        (RewardedAdOutcome.unavailable, PackTrialOutcome.adUnavailable),
      ]) {
        final controller = await loadController(
          _MemorySettingsRepository(),
          characterPacks: CharacterPackCatalog.all,
          rewardedPackTrials: true,
          showRewardedAd: (_) async => ad,
        );
        expect(
          await controller
              .watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
          expected,
        );
      }
    });

    test('체험 저장이 실패해도 광고를 본 이번 실행에는 열어 준다', () async {
      final controller = await loadController(
        _MemorySettingsRepository(),
        characterPacks: CharacterPackCatalog.all,
        rewardedPackTrials: true,
        trialStore: _MemoryTrialStore()..failSaves = true,
      );

      expect(
        await controller.watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
        PackTrialOutcome.started,
      );
      expect(controller.currentPack.id, 'poodle_garden');
    });

    test('광고를 켤 수 없는 플랫폼에서는 광고를 띄우지 않는다', () async {
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
        await controller.watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
        PackTrialOutcome.failed,
      );
      expect(shown, 0);
      expect(controller.packTrialEndsAt(CharacterPackCatalog.poodleGarden),
          isNull);
    });

    test('산 팩은 체험이 아니다', () async {
      var shown = 0;
      final controller = await loadController(
        _MemorySettingsRepository(),
        ownership: const _Owns({'poodle_garden'}),
        characterPacks: CharacterPackCatalog.all,
        rewardedPackTrials: true,
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
        await controller.watchAdForPackTrial(CharacterPackCatalog.poodleGarden),
        PackTrialOutcome.failed,
      );
      expect(shown, 0);
    });
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

class _MemoryTrialStore implements PackTrialStore {
  final Map<String, DateTime> ends = {};
  bool failSaves = false;

  @override
  Future<Map<String, DateTime>> loadTrialEnds() async => Map.of(ends);

  @override
  Future<void> saveTrialEnd(String packId, DateTime endsAt) async {
    if (failSaves) throw StateError('save failed');
    ends[packId] = endsAt;
  }
}
