import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// 광고 SDK를 한 번만 올린다.
///
/// 순서가 중요하다. **동의를 먼저 받고 SDK를 올린다.** 반대로 하면 EEA
/// 사용자에게 동의 없이 개인 맞춤 광고를 요청하게 된다.
///
/// 앱 시작을 막지 않는다. 광고는 없어도 앱이 돌아가야 하는 기능이라,
/// 여기서 기다리면 SDK가 느린 날 스플래시가 그만큼 길어진다.
class AdBootstrap {
  AdBootstrap._();

  static final AdBootstrap instance = AdBootstrap._();

  Future<void>? _initialization;
  bool _ready = false;

  /// SDK가 올라와 광고를 요청해도 되는 상태인가.
  bool get isReady => _ready;

  /// 여러 번 불러도 초기화는 한 번만 하고, **끝날 때까지 기다릴 수 있다.**
  ///
  /// bool 플래그로 «시작했음»만 표시하면, 초기화가 도는 중에 부른 쪽은
  /// 곧바로 반환받아 아직 준비 안 된 SDK에 광고를 요청하게 된다. 홈 화면은
  /// 스플래시 직후에 뜨므로 실제로 이 경합에 걸린다.
  Future<void> ensureInitialized() {
    if (!AdConfig.isPlatformSupported) return Future<void>.value();
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    await _gatherConsent();

    // 동의가 필요한데 아직 못 받았으면 광고를 요청하지 않는다.
    //
    // 여기서 막히는 가장 흔한 원인은 사용자의 거부가 아니라 **AdMob 콘솔에
    // 개인정보 보호 메시지를 안 만든 것**이다. 그러면 UMP가 동의 상태를
    // 아예 못 읽어 «알 수 없음»이 되고, 비EEA 사용자에게도 광고가 0이 된다.
    // 증상이 «광고가 그냥 안 뜬다»라서 원인을 찾기 어려우니 소리 내어 남긴다.
    if (!await ConsentInformation.instance.canRequestAds()) {
      debugPrint(
        '[ads] 동의 상태를 확인할 수 없어 SDK를 올리지 않는다. '
        'AdMob > 개인 정보 보호 및 메시지에서 GDPR 메시지를 만들었는지 확인할 것.',
      );
      return;
    }

    await MobileAds.instance.initialize();
    _ready = true;
    debugPrint('[ads] SDK 준비 완료');
  }

  /// UMP 동의 — EEA 사용자에게 동의 양식을 띄운다.
  ///
  /// 실패해도 앱을 멈추지 않는다. 동의를 못 받으면 [canRequestAds]가
  /// false를 돌려주고 광고만 뜨지 않는다.
  Future<void> _gatherConsent() async {
    final params = ConsentRequestParameters(
      // 테스터가 전부 한국에 있으면 동의 양식이 뜨지 않아 이 흐름을
      // 검증할 수 없다. 빌드 플래그로 지역을 EEA로 가장한다.
      //
      // 기기 해시를 함께 넘겨야 한다. 지역만 지정하면 UMP가 통째로 무시한다.
      consentDebugSettings:
          AdConfig.forceEeaForTesting && AdConfig.debugDeviceHash.isNotEmpty
              ? ConsentDebugSettings(
                  debugGeography: DebugGeography.debugGeographyEea,
                  testIdentifiers: [AdConfig.debugDeviceHash],
                )
              : null,
    );

    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        await ConsentForm.loadAndShowConsentFormIfRequired((error) {
          if (error != null) {
            debugPrint('[ads] 동의 양식 실패: ${error.message}');
          }
        });
        if (!completer.isCompleted) completer.complete();
      },
      (error) {
        debugPrint('[ads] 동의 정보 갱신 실패: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }
}
