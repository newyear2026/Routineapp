import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/store/pack_ad_unlock.dart';

/// 광고로 여는 팩마다 끝까지 본 광고 수 — 팩마다 키 하나.
///
/// 루틴 기록이 아니라 기기 장부다. 내보내기/가져오기로 옮겨 가면 다른
/// 기기에서 광고를 보지 않고 팩이 열리므로 `device.*` 키를 쓴다.
class LocalPackAdUnlockStore implements PackAdUnlockStore {
  const LocalPackAdUnlockStore();

  static const _prefix = 'device.pack_ad_views.';

  /// 1.0.1+4까지 쓰던 «24시간 체험» 끝나는 시각.
  ///
  /// 그때 광고를 한 번 본 사람은 한 번 본 것으로 옮긴다. 체험이 끝났어도
  /// 광고를 낸 것은 같다 — 다시 처음부터 보게 하면 30초를 떼먹는 셈이다.
  static const _legacyTrialPrefix = 'device.pack_trial_ends_ms.';

  @override
  Future<Map<String, int>> loadAdViews() async {
    final p = await SharedPreferences.getInstance();
    await _migrateLegacyTrials(p);
    return {
      for (final key in p.getKeys().where((key) => key.startsWith(_prefix)))
        if (p.getInt(key) case final count?)
          key.substring(_prefix.length): count,
    };
  }

  @override
  Future<void> saveAdViews(String packId, int count) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('$_prefix$packId', count);
  }

  Future<void> _migrateLegacyTrials(SharedPreferences p) async {
    final legacyKeys =
        p.getKeys().where((key) => key.startsWith(_legacyTrialPrefix)).toList();
    for (final key in legacyKeys) {
      final packId = key.substring(_legacyTrialPrefix.length);
      if (p.getInt('$_prefix$packId') == null) {
        await p.setInt('$_prefix$packId', 1);
      }
      await p.remove(key);
    }
  }
}
