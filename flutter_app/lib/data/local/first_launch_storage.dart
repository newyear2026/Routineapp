import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체의 첫 실행 시각. 기존 광고 워밍업 키를 그대로 사용해 테스터의
/// 기록도 보존한다.
abstract final class FirstLaunchStorage {
  static const _key = 'ads.first_launch_at_ms';

  static Future<DateTime> ensure(DateTime now) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getInt(_key);
    if (saved != null) return DateTime.fromMillisecondsSinceEpoch(saved);
    await preferences.setInt(_key, now.millisecondsSinceEpoch);
    return now;
  }
}
