import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../domain/ads/ad_slot.dart';
import '../../domain/ads/ad_slot_decision.dart';
import 'ad_bootstrap.dart';
import 'ad_policy_service.dart';
import 'ad_unit_ids.dart';

/// 보상형 광고를 한 번 띄운 결과.
enum RewardedAdOutcome {
  /// 끝까지 봐서 보상을 받았다.
  earned,

  /// 보상 전에 닫았다.
  dismissed,

  /// 오늘 볼 수 있는 횟수를 다 썼다.
  dailyCapReached,

  /// 띄우지 못했다 — SDK 미준비, 정책 거절, 로드 실패.
  unavailable,
}

/// 보상형 광고를 불러와 띄우고, 사용자가 보상을 받았는지 돌려준다.
///
/// 미리 불러 두지 않는다. 보상형은 사용자가 누를 때만 필요하고, 누르지
/// 않는 사람이 대부분이다. 미리 불러 두면 쓰지 않을 광고 요청이 쌓여
/// 채움률만 떨어진다. 대신 누른 뒤 1~3초 로딩을 버튼이 보여 준다.
class RewardedAdService {
  RewardedAdService._();

  static final RewardedAdService instance = RewardedAdService._();

  /// 광고 로드를 기다리는 한도. 넘기면 «지금은 광고가 없다»로 본다.
  static const Duration _loadTimeout = Duration(seconds: 15);

  bool _busy = false;

  Future<RewardedAdOutcome> show(AdSlot slot) async {
    // 버튼을 연달아 누르면 광고 두 개가 겹쳐 뜬다.
    if (_busy) return RewardedAdOutcome.unavailable;
    _busy = true;
    try {
      await AdBootstrap.instance.ensureInitialized();
      if (!AdBootstrap.instance.isReady) {
        debugPrint('[ads] 보상형 건너뜀: SDK가 준비되지 않았다');
        return RewardedAdOutcome.unavailable;
      }

      final decision = await AdPolicyService.instance.decide(slot);
      debugPrint('[ads] 보상형 판정: $decision (단위=${AdUnitIds.packTrialRewarded})');
      if (!decision.isAllowed) {
        return decision.reason == AdDenialReason.dailyRewardCap
            ? RewardedAdOutcome.dailyCapReached
            : RewardedAdOutcome.unavailable;
      }

      final ad = await _load();
      if (ad == null) return RewardedAdOutcome.unavailable;
      return await _present(ad, slot);
    } finally {
      _busy = false;
    }
  }

  Future<RewardedAd?> _load() {
    final completer = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: AdUnitIds.packTrialRewarded,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          // 한도를 넘겨 이미 포기한 뒤에 도착한 광고는 띄우지 않는다.
          // 사용자는 «불러올 수 없다»는 안내를 이미 봤다.
          if (completer.isCompleted) {
            ad.dispose();
            return;
          }
          completer.complete(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[ads] 보상형 로드 실패: ${error.code} ${error.message}');
          if (!completer.isCompleted) completer.complete(null);
        },
      ),
    );
    return completer.future.timeout(_loadTimeout, onTimeout: () {
      debugPrint('[ads] 보상형 로드 시간 초과');
      if (!completer.isCompleted) completer.complete(null);
      return null;
    });
  }

  Future<RewardedAdOutcome> _present(RewardedAd ad, AdSlot slot) {
    final done = Completer<RewardedAdOutcome>();
    var earned = false;

    void finish(RewardedAdOutcome outcome) {
      ad.dispose();
      if (!done.isCompleted) done.complete(outcome);
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      // 하루 상한은 «본 광고» 단위다. 불러 놓고 못 띄운 광고까지 세면
      // 사용자는 아무것도 못 봤는데 오늘 몫이 깎인다.
      onAdImpression: (_) => AdPolicyService.instance.recordShown(slot),
      onAdDismissedFullScreenContent: (_) => finish(
        earned ? RewardedAdOutcome.earned : RewardedAdOutcome.dismissed,
      ),
      onAdFailedToShowFullScreenContent: (_, error) {
        debugPrint('[ads] 보상형 표시 실패: ${error.code} ${error.message}');
        finish(RewardedAdOutcome.unavailable);
      },
    );
    // 보상은 닫기 전에 온다. 여기서 바로 팩을 풀지 않고 닫힌 뒤에 한 번에
    // 처리한다 — 광고 위에서 앱 화면이 바뀌면 닫았을 때 어디로 돌아왔는지
    // 헷갈린다.
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }
}
