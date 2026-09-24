import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 알림 아이콘은 코드가 문자열로만 가리키므로, 리소스가 사라져도 빌드는 통과한다.
/// 그 상태로 배포되면 알람은 울리는데 알림만 조용히 안 뜨는 버그가 된다.
/// 실기기에서 그 증상을 한 번 겪었기 때문에 테스트로 묶어 둔다.
void main() {
  const densities = ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi'];

  test('알림 아이콘이 밀도별로 모두 있다', () {
    for (final density in densities) {
      final file = File(
        'android/app/src/main/res/drawable-$density/ic_notification.png',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: '${file.path} 가 없다. '
            'flutter test tool/generate_notification_icon.dart 로 다시 뽑는다.',
      );
      expect(file.lengthSync(), greaterThan(0), reason: '${file.path} 가 비었다');
    }
  });

  test('리소스 축소기가 알림 아이콘을 지우지 않게 지켜 둔다', () {
    // 아이콘을 문자열로만 참조하므로 축소기가 참조를 못 본다. keep.xml 이 없으면
    // 릴리스 APK 에서만 아이콘이 사라져 디버그로는 잡히지 않는다.
    final keep = File('android/app/src/main/res/raw/keep.xml');
    expect(keep.existsSync(), isTrue, reason: '${keep.path} 가 없다');
    expect(keep.readAsStringSync(), contains('@drawable/ic_notification'));
  });

  test('알림 초기화가 런처 아이콘을 가리키지 않는다', () {
    // 어댑티브 아이콘은 상태바 아이콘으로 쓸 수 없다. 되돌아가는 것을 막는다.
    const sources = [
      'lib/application/services/routine_notification_service.dart',
      'lib/application/services/notification_permission_service.dart',
    ];
    for (final path in sources) {
      final code = File(path).readAsStringSync();
      expect(
        code.contains("AndroidInitializationSettings('@mipmap/"),
        isFalse,
        reason: '$path 가 런처 아이콘을 알림 아이콘으로 쓰고 있다',
      );
      expect(
        code.contains("AndroidInitializationSettings('@drawable/ic_notification')"),
        isTrue,
        reason: '$path 가 전용 알림 아이콘을 쓰지 않는다',
      );
    }
  });
}
