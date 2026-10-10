import 'dart:io' show Platform;

import '../../domain/ads/ad_placement_caps.dart';

/// 빌드로 주입하는 광고 설정.
///
/// `int.fromEnvironment`는 커널 컴파일 시점에 값이 박힌다.
///
/// 기본값은 언제나 «안전한 쪽»이다. 플래그를 깜빡했을 때 어느 쪽으로
/// 틀리는지가 중요하다.
///
/// - 기본값이 실제 광고였다면, 깜빡 = 지인 12명이 실제 광고를 눌러
///   무효 트래픽이 되고 AdMob 계정이 정지된다. 되돌릴 수 없다.
/// - 기본값이 테스트 광고면, 깜빡 = 프로덕션에서 수익이 0이다.
///   하루면 알아채고 고친다.
///
/// 그래서 프로덕션 빌드만 플래그를 넘긴다:
///   flutter build appbundle --release --dart-define=USE_TEST_ADS=false
abstract final class AdConfig {
  /// 테스트 광고 단위를 쓸 것인가. 기본값 true.
  static const bool useTestAds =
      bool.fromEnvironment('USE_TEST_ADS', defaultValue: true);

  static const int _warmUpHoursOverride =
      int.fromEnvironment('AD_WARMUP_HOURS', defaultValue: -1);

  /// 설치 직후 광고를 막는 기간.
  ///
  /// 비공개 테스트 빌드는 `--dart-define=AD_WARMUP_HOURS=0`으로 끈다.
  /// 그러지 않으면 테스터 상당수가 광고를 한 번도 못 본 채 14일이 끝난다.
  static Duration get warmUp => _warmUpHoursOverride < 0
      ? AdPlacementCaps.warmUp
      : const Duration(hours: _warmUpHoursOverride);

  /// 이 플랫폼에서 광고를 켤 수 있는가.
  ///
  /// iOS는 AdMob에 앱을 따로 등록해야 App ID가 나오고, 그 값이
  /// `Info.plist`의 `GADApplicationIdentifier`에 없으면 SDK 초기화 때
  /// 앱이 실행 즉시 죽는다. 등록하기 전까지 iOS는 광고를 켜지 않는다.
  ///
  /// iOS 앱을 등록하면 이 게터를 지우고 [AdUnitIds]의 iOS 실제 단위를 채운다.
  static bool get isPlatformSupported => Platform.isAndroid;

  /// 동의 양식 검증용으로 지역을 EEA로 가장할 것인가.
  ///
  /// 테스터가 전부 한국에 있으면 UMP 동의 양식이 뜨지 않아 그 흐름을
  /// 검증할 수 없다. 비공개 테스트 빌드에서만 켠다:
  ///   --dart-define=AD_DEBUG_EEA=true
  static const bool forceEeaForTesting =
      bool.fromEnvironment('AD_DEBUG_EEA', defaultValue: false);

  /// UMP 디버그 기기 해시.
  ///
  /// [forceEeaForTesting]은 **이 값 없이는 무시된다.** 기기를 디버그 기기로
  /// 등록해야 지역 가장이 먹는다. 해시는 앱을 한 번 실행하면 로그캣에 찍힌다:
  ///   `UserMessagingPlatform: Use new ConsentDebugSettings.Builder()
  ///    .addTestDeviceHashedId("...")`
  ///
  ///   --dart-define=AD_DEBUG_DEVICE=<해시>
  ///
  /// 기기마다 다르므로 코드에 박지 않는다.
  static const String debugDeviceHash =
      String.fromEnvironment('AD_DEBUG_DEVICE');
}
