import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 확인 간격과 버전별 안내 상태를 앱 재시작 후에도 유지한다.
typedef AppUpdateRecord = ({
  DateTime? checkedAt,
  DateTime? failedAt,
  int? promptedVersionCode,
  int? dismissedVersionCode,
  int? pendingVersionCode,
});

/// 사용자 백업과 분리된 기기별 기록. 시각은 UTC epoch 밀리초로 저장한다.
class AppUpdateStorage {
  AppUpdateStorage._();

  static const _kCheckedDay = 'device.update.checked_day';
  static const _kCheckedAt = 'device.update.checked_at';
  static const _kFailedAt = 'device.update.failed_at';
  static const _kPromptedCode = 'device.update.prompted_version_code';
  static const _kDismissedCode = 'device.update.dismissed_version_code';
  static const _kPendingCode = 'device.update.pending_version_code';

  static const AppUpdateRecord empty = (
    checkedAt: null,
    failedAt: null,
    promptedVersionCode: null,
    dismissedVersionCode: null,
    pendingVersionCode: null,
  );

  static Future<AppUpdateRecord> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final pendingCode = p.getInt(_kPendingCode);
      return (
        // 구버전의 checked_day는 성공 여부와 시각을 모르므로 제한에 쓰지 않는다.
        checkedAt: _readTime(p, _kCheckedAt),
        failedAt: _readTime(p, _kFailedAt),
        // 구버전에서 저장한 안내는 기존처럼 배너로 이어받는다.
        promptedVersionCode: p.getInt(_kPromptedCode) ??
            (p.containsKey(_kCheckedDay) ? pendingCode : null),
        dismissedVersionCode: p.getInt(_kDismissedCode),
        pendingVersionCode: pendingCode,
      );
    } on Object catch (error) {
      debugPrint('LOOPET: 업데이트 확인 기록을 읽지 못했다: $error');
      return empty;
    }
  }

  static Future<void> save(AppUpdateRecord record) async {
    try {
      final p = await SharedPreferences.getInstance();
      await _writeInt(p, _kCheckedAt, record.checkedAt?.millisecondsSinceEpoch);
      await _writeInt(p, _kFailedAt, record.failedAt?.millisecondsSinceEpoch);
      await _writeInt(p, _kPromptedCode, record.promptedVersionCode);
      await _writeInt(p, _kDismissedCode, record.dismissedVersionCode);
      await _writeInt(p, _kPendingCode, record.pendingVersionCode);
      await p.remove(_kCheckedDay);
    } on Object catch (error) {
      debugPrint('LOOPET: 업데이트 확인 기록을 저장하지 못했다: $error');
    }
  }

  static DateTime? _readTime(SharedPreferences p, String key) {
    final value = p.getInt(key);
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  static Future<void> _writeInt(
    SharedPreferences p,
    String key,
    int? value,
  ) =>
      value == null ? p.remove(key) : p.setInt(key, value);
}
