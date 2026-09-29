import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 사용자 문의를 받는 주소.
///
/// Play Console «스토어 등록정보 > 연락처 이메일»과 개인정보처리방침
/// (`docs/PRIVACY_POLICY.md`)에 적은 주소와 같아야 한다. 바꾸면 세 곳을
/// 함께 고친다.
const String supportEmail = 'jacoboh7307@gmail.com';

/// 설정의 «문의하기»가 여는 곳. 아무것도 열지 못하면 false.
typedef SupportContactLauncher = Future<bool> Function();

/// 메일 앱을 받는 사람·제목이 채워진 채로 연다.
///
/// 메일 앱이 없는 기기도 있다. 그때는 false를 돌려주고, 설정 화면이 주소를
/// 보여 줘 직접 보낼 수 있게 한다.
Future<bool> openSupportEmail() async {
  // `Uri(queryParameters:)`는 공백을 `+`로 바꾸는데, 메일 앱 상당수가 그것을
  // 그대로 제목에 찍는다. 퍼센트 인코딩으로 직접 만든다.
  final uri = Uri.parse(
    'mailto:$supportEmail?subject=${Uri.encodeComponent('LOOPET feedback')}',
  );
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Object catch (error) {
    debugPrint('LOOPET: 메일 앱을 열지 못했다: $error');
    return false;
  }
}
