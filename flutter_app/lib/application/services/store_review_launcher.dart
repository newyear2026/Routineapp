import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 설정의 «리뷰 남기기»가 사용자를 보낼 곳을 연다. 아무것도 열지 못하면 false.
typedef StoreReviewLauncher = Future<bool> Function();

/// 리뷰를 남길 스토어가 있는 플랫폼인가 — 없으면 설정 행 자체를 숨긴다.
///
/// iOS는 아직 App Store에 없어 보낼 주소가 없다. 출시해 App Store ID가 생기면
/// `apps.apple.com/app/id<ID>?action=write-review` 로 여기를 넓힌다.
bool get storeReviewAvailable =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

/// Google Play의 LOOPET 페이지를 연다.
///
/// 인앱 리뷰 API(`requestReview`)를 쓰지 않는 이유: 그 창은 OS가 할당량으로
/// 조용히 삼키므로, 사용자가 직접 누른 버튼이 아무 반응 없이 끝날 수 있다.
/// 버튼에는 항상 무언가가 열리는 스토어 페이지가 맞다.
Future<bool> openPlayStoreReview() async {
  final String packageName;
  try {
    packageName = (await PackageInfo.fromPlatform()).packageName;
  } on Object catch (error) {
    debugPrint('LOOPET: 패키지 이름을 읽지 못했다: $error');
    return false;
  }
  if (packageName.isEmpty) return false;
  return openPlayListingOf(packageName);
}

/// Google Play에서 [packageName]의 페이지를 연다. 아무것도 열지 못하면 false.
///
/// [referrer]는 Play 설치 리퍼러로 넘어가, 설치가 LOOPET에서 왔다는 것을 그 앱의
/// Play Console이 알 수 있게 한다.
Future<bool> openPlayListingOf(String packageName, {String? referrer}) async {
  final query = {'id': packageName, if (referrer != null) 'referrer': referrer};
  // Play 앱에서 열려야 바로 별점을 누르거나 설치할 수 있다. 웹 주소는
  // `market:` 에 답할 Play 앱이 없는 기기용 후퇴다.
  final targets = [
    Uri(scheme: 'market', host: 'details', queryParameters: query),
    Uri.https('play.google.com', '/store/apps/details', query),
  ];
  for (final target in targets) {
    try {
      if (await launchUrl(target, mode: LaunchMode.externalApplication)) {
        return true;
      }
    } on Object catch (error) {
      debugPrint('LOOPET: $target 를 열지 못했다: $error');
    }
  }
  return false;
}
