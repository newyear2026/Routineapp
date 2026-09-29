import 'package:flutter_test/flutter_test.dart';
import 'package:routine_timer/application/services/privacy_policy_link.dart';

void main() {
  // 비어 있으면 설정의 «개인정보처리방침» 행이 숨는다. 모르고 출시하지 않도록
  // 여기서 막는다. 값은 Play Console에 적은 주소와 같아야 한다.
  test('개인정보처리방침 주소가 https 로 채워져 있다', () {
    final uri = Uri.tryParse(privacyPolicyUrl);
    expect(uri, isNotNull);
    expect(uri!.scheme, 'https');
    expect(uri.host, isNotEmpty);
  });
}
