import 'character_pack.dart';

/// 산 것의 장부 — 스토어가 지급한 권리(팩 ID와 광고 제거) 집합.
///
/// 광고로 연 팩은 여기 들어가지 않는다. 그건 `PackAdUnlockStore`의 몫이라,
/// 환불로 산 권리를 거둬도 광고를 보고 연 팩은 남는다.
abstract interface class EntitlementStore {
  Future<Set<String>> load();

  Future<void> save(Set<String> entitlements);
}

/// 산 팩을 소유로 답하는 판정. [base]를 대신하지 않고 감싼다.
class PurchasedOwnership implements CharacterPackOwnership {
  PurchasedOwnership({required this.base, required Set<String> entitlements})
      : entitlements = Set.unmodifiable(entitlements);

  final CharacterPackOwnership base;
  final Set<String> entitlements;

  @override
  bool owns(CharacterPack pack) =>
      base.owns(pack) || entitlements.contains(pack.id);
}
