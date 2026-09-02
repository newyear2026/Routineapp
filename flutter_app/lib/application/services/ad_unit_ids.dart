import 'dart:io' show Platform;

import 'ad_config.dart';

/// 광고 단위 ID. 앱 전체에서 ID를 아는 곳은 여기 하나다.
///
/// 화면이나 위젯이 ID를 직접 들면 «테스트로 바꾸는 걸 깜빡한 곳»이 반드시
/// 하나 남는다. 그 하나가 지인 테스터의 클릭을 실제 광고로 만들고, 그게
/// 무효 트래픽이 되어 계정을 정지시킨다.
///
/// 테스트 여부는 [AdConfig.useTestAds]가 정하고 기본값은 테스트다.
abstract final class AdUnitIds {
  /// Google 공식 테스트 단위. 실제 수익도, 정책 위험도 없다.
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';
  static const _testNativeIos = 'ca-app-pub-3940256099942544/3986624511';
  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  /// 실제 단위 — Phase 2 프로덕션 빌드에서만 쓴다.
  ///
  /// iOS는 AdMob에 앱을 따로 등록해야 별도 ID가 나온다. 아직 없으므로
  /// iOS 프로덕션 빌드를 만들기 전에 채워야 한다.
  static const _liveNativeAndroid = 'ca-app-pub-2706404530136726/7842071773';
  static const _liveRewardedAndroid = 'ca-app-pub-2706404530136726/2917048152';

  static bool get _isIos => Platform.isIOS;

  /// Slot A — 홈 «다음 일정» 뒤.
  static String get homeUpcomingNative {
    if (AdConfig.useTestAds) {
      return _isIos ? _testNativeIos : _testNativeAndroid;
    }
    return _isIos ? _testNativeIos : _liveNativeAndroid;
  }

  /// Slot B — 설정 보너스 테마.
  static String get settingsThemeRewarded {
    if (AdConfig.useTestAds) {
      return _isIos ? _testRewardedIos : _testRewardedAndroid;
    }
    return _isIos ? _testRewardedIos : _liveRewardedAndroid;
  }
}
