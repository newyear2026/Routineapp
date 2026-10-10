import 'package:flutter/services.dart';

/// Available in Android foreground and background Flutter engines.
abstract final class RoutineNotificationPlatform {
  static const channel = MethodChannel('routine_timer/notification_platform');

  static Future<DateTime?> postedAt(int id) async {
    final data = await channel
        .invokeMapMethod<String, dynamic>('notificationInfo', {'id': id});
    final millis = data?['postedAt'] as int?;
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  static Future<void> dismiss(int id, {DateTime? postedAt}) =>
      channel.invokeMethod('dismiss', {
        'id': id,
        'postedAt': postedAt?.millisecondsSinceEpoch,
      });

  static Future<String?> timezone() => channel.invokeMethod<String>('timezone');
  static Future<bool> exactAlarmsAllowed() async =>
      await channel.invokeMethod<bool>('exactAlarmsAllowed') ?? false;

  static Future<bool> mutateLogs(String operation,
          {String? log, String? routineId, String? dateYmd}) async =>
      await channel.invokeMethod<bool>('mutateLogs', {
        'operation': operation,
        'log': log,
        'routineId': routineId,
        'dateYmd': dateYmd,
      }) ??
      false;
}
