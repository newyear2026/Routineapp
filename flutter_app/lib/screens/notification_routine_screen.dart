import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../domain/models/routine_notification_target.dart';
import '../domain/services/routine_state_resolver.dart';
import '../domain/services/routine_occurrences.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';

/// A notification always opens the named occurrence, even if another slot is active.
class NotificationRoutineScreen extends StatefulWidget {
  const NotificationRoutineScreen(
      {super.key, required this.target, this.dateYmd});
  final RoutineNotificationTarget? target;
  final String? dateYmd;

  @override
  State<NotificationRoutineScreen> createState() =>
      _NotificationRoutineScreenState();
}

class _NotificationRoutineScreenState extends State<NotificationRoutineScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<RoutineAppController>();
    final l10n = AppLocalizations.of(context);
    final target = widget.target;
    final definition =
        app.routines.where((r) => r.id == target?.routineId).firstOrNull;
    final date = DateTime.tryParse(widget.dateYmd ?? '');
    final routine = definition == null
        ? null
        : date == null
            ? definition
            : RoutineOccurrences.onDate(definition, date);
    final log = routine == null
        ? null
        : RoutineOccurrences.logFor(routine, app.occurrenceLogs, app.now);
    final current = routine != null &&
        target != null &&
        target.matches(routine) &&
        date != null &&
        routine.repeatWeekdays.contains(date.weekday) &&
        !app.now.isBefore(RoutineOccurrences.window(routine, app.now).start) &&
        app.now.isBefore(RoutineOccurrences.day(date, 1));
    final canComplete = current &&
        RoutineStateResolver.canApplyUserAction(
            routine: routine, log: log, nowLocal: app.now);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: Text(l10n.notificationRoutineTitle),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: l10n.commonBack,
            onPressed: () => context.go('/home')),
      ),
      body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
        if (!app.isLoaded) ...[
          if (app.hasBlockingLoadError)
            AppButton(label: l10n.commonRetry, onPressed: app.load)
          else
            const Center(child: CircularProgressIndicator()),
        ] else if (routine == null) ...[
          Text(l10n.routineMissingTitle, style: AppTextStyles.titleScreen),
          const SizedBox(height: 12),
          Text(l10n.routineMissingBody),
        ] else ...[
          Text(routine.title, style: AppTextStyles.titleScreen),
          const SizedBox(height: 12),
          Text(
              '${_time(context, routine.startMinutesFromMidnight)} – '
              '${_time(context, routine.endMinutesFromMidnight)}',
              style: AppTextStyles.bodyStrong),
          if (widget.dateYmd != null)
            Text(widget.dateYmd!, style: AppTextStyles.caption),
          const SizedBox(height: 24),
          if (!current) Text(l10n.notificationOccurrenceExpired),
          if (current && !canComplete)
            Text(log?.status.name == 'completed'
                ? l10n.slotAlreadyCompleted
                : log?.status.name == 'skipped'
                    ? l10n.slotSkippedNotice
                    : l10n.slotExpiredNotice),
          if (canComplete)
            AppButton(
                label: l10n.actionCompleteNamed(routine.title),
                isLoading: _saving,
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          final undo = await app.completeNotificationRoutine(
                              routine.id, widget.dateYmd!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(undo == null
                                ? l10n.notificationOccurrenceExpired
                                : l10n.homeMarkedDone),
                            action: undo == null
                                ? null
                                : SnackBarAction(
                                    label: l10n.commonUndo,
                                    onPressed: () async {
                                      try {
                                        await app.undoAction(undo);
                                      } catch (_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(l10n
                                                      .homeActionUndoFailed)));
                                        }
                                      }
                                    }),
                          ));
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(l10n.homeActionSaveFailed)));
                          }
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                      }),
        ],
        const SizedBox(height: 24),
        AppButton(
            label: l10n.navHome,
            variant: AppButtonVariant.secondary,
            onPressed: () => context.go('/home')),
      ])),
    );
  }

  String _time(BuildContext context, int minutes) =>
      TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60)
          .format(context);
}
