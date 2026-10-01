import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/store/purchase_ownership.dart';

/// 스토어가 지급한 권리 — 키 하나에 목록으로.
///
/// 광고 본 수와 같은 기기 장부라 `device.*` 키를 쓴다. 내보내기로 옮겨 가면
/// 다른 계정의 기기에서 돈을 내지 않고 팩이 열린다. 기기를 바꾸면 Play가
/// 같은 계정의 구매를 다시 보내 주므로 옮길 이유도 없다.
class LocalEntitlementStore implements EntitlementStore {
  const LocalEntitlementStore();

  static const _key = 'device.purchase_entitlements';

  @override
  Future<Set<String>> load() async {
    final p = await SharedPreferences.getInstance();
    return (p.getStringList(_key) ?? const []).toSet();
  }

  @override
  Future<void> save(Set<String> entitlements) async {
    final p = await SharedPreferences.getInstance();
    final ok = await p.setStringList(_key, entitlements.toList()..sort());
    if (!ok) throw StateError('purchase entitlements were not saved');
  }
}
