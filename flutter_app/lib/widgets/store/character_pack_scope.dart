import 'package:flutter/widgets.dart';

import '../../data/store/character_pack_catalog.dart';
import '../../domain/store/character_pack.dart';
import '../../domain/store/pack_trial.dart';

/// 지금 쓰는 팩과 팩을 바꾸는 길을 화면 트리에 내려 준다.
///
/// 캐릭터를 그리는 자리(`AnimatedCat`)는 홈·진행·설정·루틴 화면 곳곳의
/// 작은 위젯이다. 그 위젯마다 컨트롤러를 읽게 하면 디자인 시스템 위젯이
/// 앱 상태에 묶이고, 컨트롤러 없이 그리는 테스트와 미리보기가 모두 깨진다.
///
/// 스코프가 없으면 기본 팩 · 기본 소유 판정 · 바꿀 수 없음으로 답한다.
class CharacterPackScope extends InheritedWidget {
  const CharacterPackScope({
    super.key,
    required this.current,
    required this.ownership,
    this.onSelect,
    this.trialEndsAt,
    this.onStartTrial,
    required super.child,
  });

  /// 판정이 끝난 팩. 그림이 있다는 것이 보장된다.
  final CharacterPack current;

  final CharacterPackOwnership ownership;

  /// 팩을 바꾼다. 저장까지 끝나야 true다. null이면 바꿀 수 없는 자리다.
  final Future<bool> Function(CharacterPack pack)? onSelect;

  /// 광고로 체험 중인 팩이면 끝나는 시각. null이면 체험이 없는 자리다.
  final DateTime? Function(CharacterPack pack)? trialEndsAt;

  /// 광고를 보고 팩을 하루 동안 연다. null이면 광고로 열 수 없는 자리다.
  final Future<PackTrialOutcome> Function(CharacterPack pack)? onStartTrial;

  static CharacterPackScope? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CharacterPackScope>();

  static CharacterPack currentOf(BuildContext context) =>
      _maybeOf(context)?.current ?? CharacterPackCatalog.defaultPack;

  static CharacterPackOwnership ownershipOf(BuildContext context) =>
      _maybeOf(context)?.ownership ?? const BundledOnlyOwnership();

  static Future<bool> Function(CharacterPack pack)? onSelectOf(
    BuildContext context,
  ) =>
      _maybeOf(context)?.onSelect;

  static DateTime? trialEndsAtOf(BuildContext context, CharacterPack pack) =>
      _maybeOf(context)?.trialEndsAt?.call(pack);

  static Future<PackTrialOutcome> Function(CharacterPack pack)? onStartTrialOf(
          BuildContext context) =>
      _maybeOf(context)?.onStartTrial;

  /// 소유 판정은 객체가 같으면 같다고 본다. 결제가 붙어 소유가 객체 안에서
  /// 바뀌게 되면, 그 변화는 [current]가 바뀌거나 이 스코프를 새 판정
  /// 객체로 다시 만드는 쪽으로 알려야 한다.
  @override
  bool updateShouldNotify(CharacterPackScope oldWidget) =>
      current.id != oldWidget.current.id ||
      ownership != oldWidget.ownership ||
      onSelect != oldWidget.onSelect ||
      trialEndsAt != oldWidget.trialEndsAt ||
      onStartTrial != oldWidget.onStartTrial;
}
