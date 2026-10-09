import '../models/routine.dart';

/// 취침 알림 한 건 — 어느 요일 몇 시에 울리는가.
class BedtimeReminderSlot {
  const BedtimeReminderSlot({
    required this.wakeWeekday,
    required this.weekday,
    required this.minutes,
    required this.offsetFromWakeDay,
  });

  /// 이 알림이 속한 수면의 기상 요일. 수면 기록은 기상 날짜에 남는다.
  final int wakeWeekday;

  /// 알림이 실제로 울리는 요일(월=1 … 일=7).
  final int weekday;

  /// 알림이 울리는 하루 중 분(0–1439).
  final int minutes;

  /// 기상 날짜 자정 기준 몇 분 뒤인가. 전날 밤이면 음수다.
  final int offsetFromWakeDay;
}

/// 수면 루틴의 반복 요일은 **기상** 요일이다. 23시에 자고 7시에 일어나면
/// 월요일 기상의 취침 알림은 일요일 밤에 울려야 한다.
class BedtimeReminderSchedule {
  const BedtimeReminderSchedule._();

  static List<BedtimeReminderSlot> slots(Routine routine) {
    if (!routine.bedtimeAlertsEnabled) return const [];
    final offset = routine.startMinutesFromMidnight -
        (routine.crossesMidnight ? 1440 : 0) -
        routine.bedtimeReminderLeadMinutes;
    final dayShift = (offset / 1440).floor();
    final minutes = offset - dayShift * 1440;
    final wakeDays = routine.repeatWeekdays.toList()..sort();
    return [
      for (final wake in wakeDays)
        BedtimeReminderSlot(
          wakeWeekday: wake,
          weekday: (wake - 1 + dayShift) % 7 + 1,
          minutes: minutes,
          offsetFromWakeDay: offset,
        ),
    ];
  }
}
