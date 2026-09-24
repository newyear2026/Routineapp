import 'ad_placement_caps.dart';
import 'ad_policy_context.dart';
import 'ad_slot.dart';
import 'ad_slot_decision.dart';

/// 광고를 띄울지 판정하는 단 하나의 지점.
///
/// 화면은 조건을 직접 들지 않고 [decide]의 결과만 쓴다. `BUSINESS_MODEL.md`
/// 6장이 `FeatureGateService`에 대해 정한 규칙을 광고 자리에도 그대로
/// 적용한 것이다 — 게이팅 조건이 화면에 흩어지면 정책을 바꿀 수 없게 된다.
///
/// Phase 3에서 결제가 들어오면 이 판정기는 `FeatureGateService` 안으로
/// 흡수된다. 그때 화면은 손대지 않는다.
abstract final class AdSlotPolicy {
  /// 밀어 넣는 광고와 사용자가 당긴 광고는 상한이 다르다.
  ///
  /// 세션 상한과 «알림 진입 세션» 금지는 사용자가 원하지 않았는데 나타나는
  /// 광고를 막기 위한 것이다. 보상형은 사용자가 먼저 눌러야 시작하므로
  /// 그 두 상한의 대상이 아니고, 대신 하루 횟수로 제한한다.
  static AdSlotDecision decide(AdSlot slot, AdPolicyContext context) {
    if (!context.platformSupported) {
      return const AdSlotDecision.deny(AdDenialReason.platformNotSupported);
    }

    if (!slot.enabled) {
      return const AdSlotDecision.deny(AdDenialReason.slotNotEnabled);
    }

    // 결제한 사용자에게는 어떤 상한보다 먼저 광고가 사라져야 한다.
    // 보상형은 시즌 테마 체험용으로 남기므로 여기서 걸러내지 않는다.
    if (context.isPro && !slot.isUserInitiated) {
      return const AdSlotDecision.deny(AdDenialReason.proUser);
    }

    // 워밍업은 설치 직후에 광고가 «나타나는» 것을 막는 장치다. 보상형은
    // 사용자가 눌러야 시작하므로 막을 대상이 없다 — 막으면 첫 이틀 동안
    // 광고로 여는 팩이 누를 수 없는 버튼이 될 뿐이다.
    if (!slot.isUserInitiated && _isWithinWarmUp(context)) {
      return const AdSlotDecision.deny(AdDenialReason.warmUp);
    }

    if (!slot.isUserInitiated) {
      if (context.startedFromNotification) {
        return const AdSlotDecision.deny(AdDenialReason.notificationEntry);
      }
      if (context.nativeImpressionsThisSession >=
          AdPlacementCaps.nativeImpressionsPerSession) {
        return const AdSlotDecision.deny(AdDenialReason.sessionCap);
      }
      if (context.slotsShownThisSession.contains(slot)) {
        return const AdSlotDecision.deny(AdDenialReason.slotAlreadyShown);
      }
    } else if (context.rewardedShownToday >= AdPlacementCaps.rewardedPerDay) {
      return const AdSlotDecision.deny(AdDenialReason.dailyRewardCap);
    }

    if (!_slotContentReady(slot, context)) {
      return const AdSlotDecision.deny(AdDenialReason.slotCondition);
    }

    return const AdSlotDecision.allow();
  }

  static bool _isWithinWarmUp(AdPolicyContext context) {
    if (context.warmUp <= Duration.zero) return false;
    // 첫 실행이라 기록이 없으면 경과 시간은 0이다.
    final firstLaunch = context.firstLaunchAt;
    if (firstLaunch == null) return true;
    return context.now.difference(firstLaunch) < context.warmUp;
  }

  /// 자리마다 «지금 이 화면에 광고를 얹어도 되는가»가 다르다.
  static bool _slotContentReady(AdSlot slot, AdPolicyContext context) {
    switch (slot) {
      case AdSlot.homeUpcoming:
        return context.upcomingCount >= AdPlacementCaps.minUpcomingForHomeSlot;
      case AdSlot.progressBeforeUpcoming:
        return context.todayRoutineCount >=
            AdPlacementCaps.minTodayRoutinesForProgressSlot;
      case AdSlot.packTrialReward:
        // 잠긴 팩에서 사용자가 눌렀을 때만 호출되므로 별도 조건이 없다.
        return true;
    }
  }
}
