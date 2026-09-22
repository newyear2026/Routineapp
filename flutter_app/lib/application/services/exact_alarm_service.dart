import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

/// 정확 알람 권한이 지금 살아 있는지 확인한다.
///
/// 앱은 USE_EXACT_ALARM 을 선언한다. 설치할 때 자동으로 허용되고 사용자가 끌 수
/// 없으므로 Android 13+ 에서는 언제나 true 다. 켜달라고 보낼 화면도, 그래서
/// 설정 UI 도 없다.
///
/// 그런데도 이 조회가 남아 있는 이유는 Android 12~12L(API 31~32) 다. 거기에는
/// USE_EXACT_ALARM 이 없어 SCHEDULE_EXACT_ALARM 으로 떨어지는데, 그건 사용자가
/// 시스템 설정에서 끌 수 있다. 꺼진 채로 정확 알람을 걸면 SecurityException 으로
/// 예약 자체가 실패하므로, 호출부는 이 값을 보고 부정확 알람으로 후퇴한다.
///
/// Android 12 미만과 다른 플랫폼에는 이 개념이 없다. 그 경우 항상 허용으로 본다 —
/// 알람이 이미 정확하게 울리기 때문이다.
class ExactAlarmService {
  ExactAlarmService._();
  static final ExactAlarmService instance = ExactAlarmService._();

  static const MethodChannel _channel =
      MethodChannel('routine_timer/exact_alarm');

  bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> canScheduleExactAlarms() async {
    if (!_isAndroid) return true;
    try {
      final granted = await _channel.invokeMethod<bool>('canScheduleExactAlarms');
      return granted ?? true;
    } on PlatformException {
      // 채널이 없거나 실패하면 부정확 알람으로 후퇴한다. 알림 자체는 계속 동작한다.
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
