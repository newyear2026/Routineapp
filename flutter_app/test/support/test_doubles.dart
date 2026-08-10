import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:routine_timer/application/services/routine_notification_service.dart';
import 'package:routine_timer/data/repositories/routine_log_repository.dart';
import 'package:routine_timer/data/repositories/routine_repository.dart';
import 'package:routine_timer/domain/models/routine.dart';
import 'package:routine_timer/domain/models/routine_log.dart';
import 'package:routine_timer/domain/utils/time_minutes.dart';

/// 메모리 루틴 저장소.
class MemoryRoutineRepository implements RoutineRepository {
  MemoryRoutineRepository([List<Routine> initial = const []])
      : items = List.of(initial);

  final List<Routine> items;

  @override
  Future<void> addRoutine(Routine routine) async => items.add(routine);

  @override
  Future<void> deleteRoutine(String routineId) async {
    items.removeWhere((routine) => routine.id == routineId);
  }

  @override
  Future<List<Routine>> loadRoutines() async => List.of(items);

  @override
  Future<void> saveRoutines(List<Routine> routines) async {
    items
      ..clear()
      ..addAll(routines);
  }

  @override
  Future<void> upsertRoutine(Routine routine) async {
    final index = items.indexWhere((item) => item.id == routine.id);
    if (index == -1) {
      items.add(routine);
    } else {
      items[index] = routine;
    }
  }
}

/// 메모리 로그 저장소.
///
/// 날짜별 조회를 실제로 구현한다 — 완료/스킵 같은 액션 결과를 다시 읽어야
/// 홈 화면의 상태 변화를 검증할 수 있다.
class MemoryLogRepository implements RoutineLogRepository {
  final List<RoutineLog> logs = [];

  @override
  Future<void> deleteLogForRoutineOnDate(
    String routineId,
    String dateYmd,
  ) async {
    logs.removeWhere(
      (log) => log.routineId == routineId && log.dateYmd == dateYmd,
    );
  }

  @override
  Future<void> deleteLogsForRoutine(String routineId) async {
    logs.removeWhere((log) => log.routineId == routineId);
  }

  @override
  Future<List<RoutineLog>> loadAllLogs() async => List.of(logs);

  @override
  Future<List<RoutineLog>> loadLogsForDate(DateTime dateLocal) async {
    final ymd = TimeMinutes.dateYmd(dateLocal);
    return logs.where((log) => log.dateYmd == ymd).toList();
  }

  @override
  Future<void> upsertLog(RoutineLog log) async {
    final index = logs.indexWhere(
      (item) => item.routineId == log.routineId && item.dateYmd == log.dateYmd,
    );
    if (index == -1) {
      logs.add(log);
    } else {
      logs[index] = log;
    }
  }
}

class NoopNotificationGateway implements LocalNotificationGateway {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PendingNotificationRequest>>
      pendingNotificationRequests() async => const [];

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    required NotificationDetails details,
    required String payload,
  }) async {}
}

/// 매일 반복하는 테스트용 루틴.
Routine dailyRoutine({
  required String id,
  required String title,
  required int startHour,
  required int endHour,
  String emoji = '🌱',
  int colorValue = 0xFF6C4CF1,
  int updatedAtMs = 1,
}) {
  return Routine(
    id: id,
    title: title,
    startMinutesFromMidnight: startHour * 60,
    endMinutesFromMidnight: endHour * 60,
    repeatWeekdays: const {1, 2, 3, 4, 5, 6, 7},
    colorValue: colorValue,
    iconEmoji: emoji,
    updatedAtMs: updatedAtMs,
  );
}

/// 알림 플러그인이 예외를 던지는 상황을 재현한다.
///
/// 실제로 릴리즈 빌드에서 `pendingNotificationRequests()`가
/// `PlatformException(Missing type parameter.)`를 던졌다.
class ThrowingNotificationGateway implements LocalNotificationGateway {
  @override
  Future<void> cancel(int id) async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<List<PendingNotificationRequest>> pendingNotificationRequests() async {
    throw PlatformException(code: 'error', message: 'Missing type parameter.');
  }

  @override
  Future<void> scheduleWeekly({
    required int id,
    required String title,
    required String body,
    required int weekday,
    required TimeOfDay time,
    required NotificationDetails details,
    required String payload,
  }) async {}
}
