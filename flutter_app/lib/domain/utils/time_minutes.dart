import 'package:flutter/material.dart';

abstract final class TimeMinutes {
  static int fromDateTime(DateTime d) => d.hour * 60 + d.minute;

  static int fromTimeOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  /// `HH:mm` 24시간 형식
  static String formatHm(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  static String dateYmd(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
