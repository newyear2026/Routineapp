import 'package:flutter/material.dart';

abstract final class TimeMinutes {
  static int fromDateTime(DateTime d) => d.hour * 60 + d.minute;

  static int fromTimeOfDay(TimeOfDay t) => t.hour * 60 + t.minute;

  /// `HH:mm` 24시간 형식
  ///
  /// 앱 전체에서 시각을 문자로 만드는 곳은 여기 하나다. 화면마다 따로 구현하면
  /// 포맷을 바꿀 때 어딘가 하나가 남는다 (실제로 5벌이 돌아다녔다).
  static String formatHm(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${formatTwoDigits(h)}:${formatTwoDigits(m)}';
  }

  /// 시각의 한 조각을 두 자리로: `9` → `09`
  ///
  /// 시각 선택기처럼 시와 분을 따로 보여주는 화면에서 쓴다.
  /// 자릿수 채우기도 여기 하나로 모아, 포맷이 갈라지지 않게 한다.
  static String formatTwoDigits(int value) => value.toString().padLeft(2, '0');

  /// `HH:mm–HH:mm` — 구분자는 en dash, 공백 없음
  static String formatRange(int startMinutes, int endMinutes) =>
      '${formatHm(startMinutes)}–${formatHm(endMinutes)}';

  /// [TimeOfDay]를 그대로 `HH:mm`으로
  static String formatTimeOfDay(TimeOfDay time) =>
      formatHm(fromTimeOfDay(time));

  static String dateYmd(DateTime local) =>
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
