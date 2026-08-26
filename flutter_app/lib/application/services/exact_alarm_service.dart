import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/services.dart';

/// 정확 알람(SCHEDULE_EXACT_ALARM) 권한 상태 조회와 시스템 설정 이동.
///
/// 이 권한은 앱이 대화상자로 받을 수 없다. 사용자를 시스템 설정 화면으로 보내고,
/// 돌아온 뒤 상태를 다시 읽는 방식만 가능하다. 그래서 «허용/거부» 결과를
/// 돌려주는 API 가 없고, 호출부가 복귀 시점에 [canScheduleExactAlarms] 를
/// 다시 물어야 한다.
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

  /// 시스템 설정 화면을 연다. 사용자가 무엇을 골랐는지는 알 수 없으므로,
  /// 앱으로 돌아온 뒤 [canScheduleExactAlarms] 로 다시 확인해야 한다.
  Future<void> openSettings() async {
    if (!_isAndroid) return;
    try {
      await _channel.invokeMethod<void>('openSettings');
    } on PlatformException {
      // 설정 화면이 없는 기기도 있다. 열지 못해도 앱 흐름은 막지 않는다.
    } on MissingPluginException {
      // 같은 이유.
    }
  }
}
