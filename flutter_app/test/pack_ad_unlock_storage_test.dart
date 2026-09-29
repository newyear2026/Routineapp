import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/data/local/pack_ad_unlock_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('본 광고 수를 팩마다 저장하고 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    const store = LocalPackAdUnlockStore();

    await store.saveAdViews('poodle_garden', 1);
    expect(await store.loadAdViews(), {'poodle_garden': 1});

    await store.saveAdViews('poodle_garden', 2);
    expect(await store.loadAdViews(), {'poodle_garden': 2});
  });

  test('옛 24시간 체험 기록은 광고 한 번으로 옮기고 지운다', () async {
    SharedPreferences.setMockInitialValues({
      'device.pack_trial_ends_ms.poodle_garden':
          DateTime(2026, 9, 24, 10).millisecondsSinceEpoch,
    });
    const store = LocalPackAdUnlockStore();

    expect(await store.loadAdViews(), {'poodle_garden': 1});
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.contains('pack_trial')), isEmpty);
  });

  test('새 기록이 이미 있으면 옛 체험 기록이 덮어쓰지 않는다', () async {
    SharedPreferences.setMockInitialValues({
      'device.pack_trial_ends_ms.poodle_garden':
          DateTime(2026, 9, 24, 10).millisecondsSinceEpoch,
      'device.pack_ad_views.poodle_garden': 2,
    });
    const store = LocalPackAdUnlockStore();

    expect(await store.loadAdViews(), {'poodle_garden': 2});
  });
}
