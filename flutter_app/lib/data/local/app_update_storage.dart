import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 업데이트 안내가 앱을 껐다 켜도 기억해야 하는 값 셋.
///
/// 한 번에 읽고 한 번에 쓴다. 세 값은 늘 같이 판단되므로 따로 읽으면 왕복만
/// 늘고, 중간 상태가 저장될 틈이 생긴다.
typedef AppUpdateRecord = ({
  String? checkedDay,
  int? dismissedVersionCode,
  int? pendingVersionCode,
});

/// [AppUpdateRecord]의 로컬 보관소.
///
/// 루틴·설정과 달리 이것은 **사용자 데이터가 아니라 기기 장부**다. 백업에
/// 실려 다른 기기로 복원되면 «이미 미뤘음»이 실제 업데이트를 침묵시키고,
/// 손상 복구 경로가 있는 루틴 blob을 괜히 키우게 된다. 그래서 키 이름도
/// `domain.*`이 아니라 `device.*`로 나눠 둔다.
class AppUpdateStorage {
  AppUpdateStorage._();

  static const _kCheckedDay = 'device.update.checked_day';
  static const _kDismissedCode = 'device.update.dismissed_version_code';
  static const _kPendingCode = 'device.update.pending_version_code';

  static const AppUpdateRecord empty = (
    checkedDay: null,
    dismissedVersionCode: null,
    pendingVersionCode: null,
  );

  static Future<AppUpdateRecord> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      return (
        checkedDay: p.getString(_kCheckedDay),
        dismissedVersionCode: p.getInt(_kDismissedCode),
        pendingVersionCode: p.getInt(_kPendingCode),
      );
    } on Object catch (error) {
      // 읽지 못한 기기는 스토어에 한 번 더 묻거나 한 번 더 끼어든다.
      // 둘 다 오류 경로를 만들 만한 일이 아니다.
      debugPrint('LOOPET: 업데이트 확인 기록을 읽지 못했다: $error');
      return empty;
    }
  }

  /// 값이 null이면 키를 지운다. «없음»과 «0»은 다른 뜻이다.
  static Future<void> save(AppUpdateRecord record) async {
    try {
      final p = await SharedPreferences.getInstance();
      await _writeString(p, _kCheckedDay, record.checkedDay);
      await _writeInt(p, _kDismissedCode, record.dismissedVersionCode);
      await _writeInt(p, _kPendingCode, record.pendingVersionCode);
    } on Object catch (error) {
      debugPrint('LOOPET: 업데이트 확인 기록을 저장하지 못했다: $error');
    }
  }

  static Future<void> _writeString(
    SharedPreferences p,
    String key,
    String? value,
  ) =>
      value == null ? p.remove(key) : p.setString(key, value);

  static Future<void> _writeInt(
    SharedPreferences p,
    String key,
    int? value,
  ) =>
      value == null ? p.remove(key) : p.setInt(key, value);
}
