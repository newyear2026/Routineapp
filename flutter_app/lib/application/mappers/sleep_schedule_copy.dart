import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/routine.dart';
import '../../domain/utils/app_date_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../domain/utils/time_minutes.dart';

abstract final class SleepScheduleCopy {
  static String time(AppLocalizations l10n, TimeOfDay time,
      {bool compact = false}) {
    final date = DateTime(2026, 1, 1, time.hour, time.minute);
    if (l10n.localeName == 'ko' && compact && time.minute == 0) {
      return DateFormat('a h시', 'ko').format(date);
    }
    return DateFormat.jm(l10n.localeName).format(date);
  }

  static String days(AppLocalizations l10n, Set<int> weekdays) {
    final days = weekdays.toList()..sort();
    if (days.isEmpty) return l10n.validationPickOneDay;
    String label(int d) =>
        AppDateFormats.weekdayShortByIndexIn(l10n.localeName, d);
    final consecutive =
        days.length > 2 && days.last - days.first == days.length - 1;
    if (consecutive) {
      return '${label(days.first)}${l10n.localeName == 'ko' ? '~' : '–'}${label(days.last)}';
    }
    return days.map(label).join('·');
  }

  static String summary(AppLocalizations l10n, Routine r) {
    if (r.repeatWeekdays.isEmpty) return l10n.validationPickOneDay;
    final wake = time(
        l10n,
        TimeOfDay(
            hour: r.endMinutesFromMidnight ~/ 60,
            minute: r.endMinutesFromMidnight % 60),
        compact: true);
    final repeat = days(l10n, r.repeatWeekdays);
    return r.wakeNotificationEnabled
        ? l10n.sleepAlarmSummary(repeat, wake)
        : l10n.sleepScheduleSummary(repeat, wake);
  }

  static String range(
      AppLocalizations l10n, Routine routine, DateTime? displayDate) {
    final start = TimeMinutes.formatHm(routine.startMinutesFromMidnight);
    final end = TimeMinutes.formatHm(routine.endMinutesFromMidnight);
    if (!routine.crossesMidnight) return '$start–$end';
    final wake = routine.occurrenceDate;
    final morning = displayDate != null &&
        wake != null &&
        wake.year == displayDate.year &&
        wake.month == displayDate.month &&
        wake.day == displayDate.day;
    return morning
        ? '${l10n.sleepPreviousDay} $start → $end'
        : '$start → ${l10n.sleepNextDay} $end';
  }

  static String duration(AppLocalizations l10n, Routine r) {
    final minutes = r.durationMinutes;
    final h = minutes ~/ 60, m = minutes % 60;
    final text = h == 0
        ? l10n.durationMinutes(m)
        : m == 0
            ? l10n.durationHours(h)
            : l10n.durationHoursMinutes(h, m);
    return l10n.sleepDuration(text);
  }
}
