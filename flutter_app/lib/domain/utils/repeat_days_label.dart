import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'app_date_formats.dart';

/// 반복 요일 집합을 사람이 읽는 한 줄로 요약한다.
///
/// 루틴 목록·폼·미리보기가 같은 문구를 쓰도록 한곳에 둔다.
/// 요일 이름과 요약 문구는 언어마다 다르므로 [BuildContext]를 받는다.
abstract final class RepeatDaysLabel {
  static const _weekdays = {1, 2, 3, 4, 5};
  static const _weekend = {6, 7};

  /// [repeatWeekdays]는 월=1 … 일=7.
  static String of(BuildContext context, Set<int> repeatWeekdays) {
    final l10n = AppLocalizations.of(context);
    if (repeatWeekdays.isEmpty) return l10n.repeatNone;
    if (repeatWeekdays.length == 7) return l10n.repeatDaily;
    if (repeatWeekdays.length == _weekdays.length &&
        repeatWeekdays.containsAll(_weekdays)) {
      return l10n.repeatWeekdays;
    }
    if (repeatWeekdays.length == _weekend.length &&
        repeatWeekdays.containsAll(_weekend)) {
      return l10n.repeatWeekend;
    }

    final sorted = repeatWeekdays.toList()..sort();
    return sorted
        .where((day) => day >= 1 && day <= 7)
        .map((day) => AppDateFormats.weekdayShortByIndex(context, day))
        .join(' · ');
  }
}
