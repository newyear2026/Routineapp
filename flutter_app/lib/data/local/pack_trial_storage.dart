import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/store/pack_trial.dart';

/// 광고로 연 팩 체험의 끝나는 시각 — 팩마다 키 하나.
///
/// 루틴 기록이 아니라 기기 장부다. 내보내기/가져오기로 옮겨 가면 다른
/// 기기에서 광고를 보지 않고 팩이 열리므로 `device.*` 키를 쓴다.
class LocalPackTrialStore implements PackTrialStore {
  const LocalPackTrialStore();

  static const _prefix = 'device.pack_trial_ends_ms.';

  @override
  Future<Map<String, DateTime>> loadTrialEnds() async {
    final p = await SharedPreferences.getInstance();
    return {
      for (final key in p.getKeys().where((key) => key.startsWith(_prefix)))
        if (p.getInt(key) case final ms?)
          key.substring(_prefix.length):
              DateTime.fromMillisecondsSinceEpoch(ms),
    };
  }

  @override
  Future<void> saveTrialEnd(String packId, DateTime endsAt) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt('$_prefix$packId', endsAt.millisecondsSinceEpoch);
  }
}
