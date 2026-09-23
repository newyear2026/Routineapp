import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/routine_app_controller.dart';
import 'package:routine_timer/application/services/routine_data_service.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/settings_repository.dart';
import 'package:routine_timer/data/store/character_pack_catalog.dart';
import 'package:routine_timer/domain/models/app_settings.dart';
import 'package:routine_timer/domain/models/watch_state.dart';
import 'package:routine_timer/domain/settings/notification_preferences.dart';
import 'package:routine_timer/domain/store/character_pack.dart';

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
      characterPacks: packs,
      nowProvider: () => DateTime(2026, 9, 22, 10, 0),
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
