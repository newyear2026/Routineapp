import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// 로케일별 날짜·요일 표기.
///
/// `'${month}월 ${day}일'` 처럼 형식을 직접 이어 붙이면 언어마다 어순이
/// 달라져 번역으로는 고칠 수 없다(es는 `21 de agosto`, en은 `Aug 21`).
/// 형식은 [DateFormat]이 로케일에서 가져오고, 여기서는 어떤 형식을 쓸지만
/// 정한다.
class AppDateFormats {
  const AppDateFormats._();

  static String _locale(BuildContext context) =>
      Localizations.localeOf(context).toLanguageTag();

  /// `8월 21일` · `Aug 21` · `21 ago`
  static String monthDay(BuildContext context, DateTime date) =>
      monthDayIn(_locale(context), date);

  /// `2026년 8월` · `August 2026` · `agosto de 2026`
  static String yearMonth(BuildContext context, DateTime date) =>
      DateFormat.yMMMM(_locale(context)).format(date);

  /// 요일 한 글자~약어: `월` · `Mon` · `lun`
  static String weekdayShort(BuildContext context, DateTime date) =>
      DateFormat.E(_locale(context)).format(date);

  /// `월요일` · `Monday` · `lunes`
  static String weekdayFull(BuildContext context, DateTime date) =>
      weekdayFullIn(_locale(context), date);

  // --- BuildContext가 없는 곳(스냅샷 조립·위젯 동기화)에서 쓰는 변형 ---

  static String monthDayIn(String localeName, DateTime date) =>
      DateFormat.MMMd(localeName).format(date);

  static String weekdayFullIn(String localeName, DateTime date) =>
      DateFormat.EEEE(localeName).format(date);

  static String weekdayShortByIndexIn(String localeName, int weekday) =>
      DateFormat.E(localeName).format(DateTime(2024, 1, weekday));

  /// 월요일=1 … 일요일=7 기준의 요일 약어. 달력 헤더처럼 날짜가 없는 곳에서 쓴다.
  ///
  /// 2024-01-01이 월요일이라 그 주를 기준 주로 삼는다.
  static String weekdayShortByIndex(BuildContext context, int weekday) =>
      weekdayShort(context, DateTime(2024, 1, weekday));

  static String weekdayFullByIndex(BuildContext context, int weekday) =>
      weekdayFull(context, DateTime(2024, 1, weekday));
}
