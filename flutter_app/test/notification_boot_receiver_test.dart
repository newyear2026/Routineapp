import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 재부팅 후에도 루틴 알림이 살아남는지를 매니페스트 수준에서 지킨다.
///
/// 이 짝이 깨지면 증상이 «재부팅하면 알림이 전부 사라진다»인데, 빌드는
/// 통과하고 경고도 없다. 앱을 다시 열면 재예약되므로 개발 중에는 거의
/// 드러나지 않는다 — 밤에 폰을 껐다 켜고 앱을 안 연 사용자만 겪는다.
void main() {
  final manifest =
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

  group('부팅 후 알림 복구', () {
    test('부팅 리시버가 등록돼 있다', () {
      expect(
        manifest.contains('ScheduledNotificationBootReceiver'),
        isTrue,
        reason: '재부팅 후 예약을 되살릴 리시버가 없다',
      );
      expect(manifest.contains('android.intent.action.BOOT_COMPLETED'), isTrue);
    });

    test('리시버와 RECEIVE_BOOT_COMPLETED 권한은 짝이다', () {
      // 안드로이드는 이 권한을 선언한 앱에만 부팅 완료 브로드캐스트를 보낸다.
      // 리시버만 있으면 영원히 호출되지 않는 코드가 된다.
      final hasReceiver =
          manifest.contains('android.intent.action.BOOT_COMPLETED');
      final hasPermission =
          manifest.contains('android.permission.RECEIVE_BOOT_COMPLETED');

      expect(
        hasReceiver && !hasPermission,
        isFalse,
        reason: 'BOOT_COMPLETED 리시버가 있는데 RECEIVE_BOOT_COMPLETED 권한이 없다. '
            '재부팅하면 예약된 알림이 전부 사라진다.',
      );
      expect(
        hasPermission && !hasReceiver,
        isFalse,
        reason: 'RECEIVE_BOOT_COMPLETED 권한만 있고 받을 리시버가 없다.',
      );
    });

    test('권한을 앱이 직접 선언한다 — 플러그인에 기대지 않는다', () {
      // flutter_local_notifications 22.3.0 은 VIBRATE 와 POST_NOTIFICATIONS 만
      // 선언한다. 예전 버전이 이 권한을 대신 선언해줘서 병합으로 따라왔고,
      // 플러그인을 올렸을 때 조용히 사라졌다. 다시 남에게 맡기지 않는다.
      final pubspecLock = File('pubspec.lock').readAsStringSync();
      expect(
        pubspecLock.contains('flutter_local_notifications'),
        isTrue,
        reason: '이 테스트의 전제가 바뀌었다',
      );
      expect(
        manifest.contains('android.permission.RECEIVE_BOOT_COMPLETED'),
        isTrue,
      );
    });
  });
}
