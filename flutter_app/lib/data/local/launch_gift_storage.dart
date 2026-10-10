import 'package:shared_preferences/shared_preferences.dart';

abstract final class LaunchGiftStorage {
  static const _seenKey = 'launch_gift.cat_stargazer.seen';

  static Future<bool> hasSeen() async =>
      (await SharedPreferences.getInstance()).getBool(_seenKey) ?? false;

  static Future<void> markSeen() async =>
      (await SharedPreferences.getInstance()).setBool(_seenKey, true);
}
