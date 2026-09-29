import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Play Console «앱 콘텐츠 > 개인정보처리방침»에 적은 주소와 **같아야** 한다.
///
/// 문서 원본은 `docs/PRIVACY_POLICY.md`, 웹 페이지는 저장소 루트의
/// `docs/privacy/index.html`이다. 주소를 옮기면 Play Console과 여기를 함께
/// 고친다. 비어 있으면 설정의 행이 숨고 `privacy_policy_link_test`가 실패한다.
const String privacyPolicyUrl =
    'https://newyear2026.github.io/Routineapp/privacy/';

/// 설정의 «개인정보처리방침»이 여는 곳. 아무것도 열지 못하면 false.
typedef PrivacyPolicyLauncher = Future<bool> Function();

/// 개인정보처리방침을 브라우저로 연다.
Future<bool> openPrivacyPolicyPage() async {
  final uri = Uri.tryParse(privacyPolicyUrl);
  if (uri == null || !uri.hasScheme) return false;
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object catch (error) {
    debugPrint('LOOPET: 개인정보처리방침을 열지 못했다: $error');
    return false;
  }
}
