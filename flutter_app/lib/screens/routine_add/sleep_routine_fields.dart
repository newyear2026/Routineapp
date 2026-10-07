import 'package:flutter/material.dart';
import '../../application/mappers/sleep_schedule_copy.dart';
import '../../domain/models/routine.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../widgets/ds/app_field_message.dart';
import '../../widgets/ds/app_pixel_switch.dart';
import '../../widgets/ds/routine_mark.dart';
import 'routine_form_controls.dart';

/// Sleep-specific form; scheduling and localized copy live outside the screen.
class SleepRoutineFields extends StatelessWidget {
  const SleepRoutineFields(
      {super.key,
      required this.routine,
      required this.start,
      required this.end,
      required this.weekdays,
      required this.onStart,
      required this.onEnd,
      required this.onWeekday,
      required this.alarmEnabled,
      required this.onAlarm,
      this.timeError,
      this.daysError});
  final Routine routine;
  final TimeOfDay start, end;
  final List<bool> weekdays;
  final VoidCallback onStart, onEnd;
  final void Function(int, bool) onWeekday;
  final bool alarmEnabled;
  final ValueChanged<bool> onAlarm;
  final String? timeError, daysError;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startLabel = SleepScheduleCopy.time(l10n, start);
    final endLabel = SleepScheduleCopy.time(l10n, end);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RoutineFormSurface(
          child: Row(children: [
        RoutineMark(icon: routine.iconId, color: routine.color, size: 52),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(routine.title, style: AppTextStyles.titleSection),
          const SizedBox(height: 4),
          Text(
              '$startLabel → ${routine.crossesMidnight ? '${l10n.sleepNextDay} ' : ''}$endLabel',
              style: AppTextStyles.caption),
        ])),
      ])),
      const SizedBox(height: 22),
      Text(l10n.sleepBedtimeQuestion, style: AppTextStyles.titleSection),
      const SizedBox(height: 10),
      _TimeButton(
          key: const Key('sleep-bedtime'),
          label: startLabel,
          semantics: l10n.sleepBedtimeQuestion,
          onTap: onStart),
      const SizedBox(height: 22),
      Text(l10n.sleepWakeQuestion, style: AppTextStyles.titleSection),
      const SizedBox(height: 10),
      _TimeButton(
          key: const Key('sleep-wake-time'),
          label: endLabel,
          semantics: l10n.sleepWakeQuestion,
          onTap: onEnd,
          badge: routine.crossesMidnight ? l10n.sleepNextDay : null),
      const SizedBox(height: 12),
      if (timeError != null)
        AppFieldMessage(message: timeError!, isError: true)
      else
        Text(SleepScheduleCopy.duration(l10n, routine),
            style:
                AppTextStyles.bodyStrong.copyWith(color: AppColors.textMuted)),
      const SizedBox(height: 24),
      Text(l10n.sleepDaysQuestion, style: AppTextStyles.titleSection),
      const SizedBox(height: 12),
      Row(
          children: List.generate(
              7,
              (i) => Expanded(
                      child: RoutineWeekdayCircle(
                    weekday: i + 1,
                    selected: weekdays[i],
                    onTap: () => onWeekday(i, !weekdays[i]),
                  )))),
      const SizedBox(height: 10),
      if (daysError != null)
        AppFieldMessage(message: daysError!, isError: true)
      else
        Text(SleepScheduleCopy.summary(l10n, routine),
            key: const Key('sleep-summary'), style: AppTextStyles.caption),
      const SizedBox(height: 24),
      RoutineFormSurface(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  Expanded(
                      child: Text(l10n.sleepWakeAlarm,
                          style: AppTextStyles.titleSection)),
                  AppPixelSwitch(
                      key: const Key('sleep-wake-alarm'),
                      value: alarmEnabled,
                      onChanged: onAlarm,
                      label: l10n.sleepWakeAlarm),
                ]),
                const SizedBox(height: 4),
                // 지속 알람이 아니라 한 번 보내는 알림임을 알린다.
                // 문장마다 줄을 나눠 한국어가 단어 중간에서 끊기지 않게 한다.
                Text(l10n.sleepWakeAlarmHint,
                    key: const Key('sleep-wake-alarm-hint'),
                    style: AppTextStyles.caption),
                Text(l10n.sleepWakeAlarmSoundHint,
                    style: AppTextStyles.caption),
              ])),
    ]);
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton(
      {super.key,
      required this.label,
      required this.semantics,
      required this.onTap,
      this.badge});
  final String label, semantics;
  final String? badge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: semantics,
        child: InkWell(
            onTap: onTap,
            child: RoutineFormSurface(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    Text(label,
                        style:
                            AppTextStyles.titleScreen.copyWith(fontSize: 28)),
                    if (badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: ShapeDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: .12),
                          shape: AppPixelStyle.shape(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        child: Text(badge!,
                            style: AppTextStyles.bodyStrong.copyWith(
                                color: Theme.of(context).colorScheme.primary)),
                      ),
                  ]),
            )),
      );
}
