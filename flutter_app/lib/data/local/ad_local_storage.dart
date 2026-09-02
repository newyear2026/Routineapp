import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/utils/time_minutes.dart';

/// 광고 상한 판정에 필요한 값 중 앱을 껐다 켜도 남아야 하는 것들.
///
/// 세션 안에서만 사는 값(이번 세션 노출 수 등)은 여기 두지 않는다.
class AdLocalStorage {
  AdLocalStorage._();

  static const _kFirstLaunchAt = 'ads.first_launch_at_ms';
  static const _kRewardedDate = 'ads.rewarded_date';
  static const _kRewardedCount = 'ads.rewarded_count';

  /// 앱을 처음 실행한 시각. 없으면 [now]로 기록하고 그 값을 돌려준다.
  ///
  /// 워밍업의 기준점이다. 설치 시각을 OS에서 읽지 않고 첫 실행 시각을
  /// 쓰는 이유는, 설치만 하고 열지 않은 기간까지 워밍업으로 소진되면
  /// 정작 앱을 처음 쓰는 사람에게 첫날부터 광고가 뜨기 때문이다.
  static Future<DateTime> ensureFirstLaunchAt(DateTime now) async {
    final p = await SharedPreferences.getInstance();
    final stored = p.getInt(_kFirstLaunchAt);
    if (stored != null) {
      return DateTime.fromMillisecondsSinceEpoch(stored);
    }
    await p.setInt(_kFirstLaunchAt, now.millisecondsSinceEpoch);
    return now;
  }

  /// 오늘 보상형 광고를 몇 번 봤는가. 날짜가 바뀌면 0이다.
  static Future<int> rewardedShownToday(DateTime now) async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kRewardedDate) != TimeMinutes.dateYmd(now)) return 0;
    return p.getInt(_kRewardedCount) ?? 0;
  }

  static Future<void> recordRewardedShown(DateTime now) async {
    final p = await SharedPreferences.getInstance();
    final today = TimeMinutes.dateYmd(now);
    final count = p.getString(_kRewardedDate) == today
        ? (p.getInt(_kRewardedCount) ?? 0)
        : 0;
    await p.setString(_kRewardedDate, today);
    await p.setInt(_kRewardedCount, count + 1);
  }
}
