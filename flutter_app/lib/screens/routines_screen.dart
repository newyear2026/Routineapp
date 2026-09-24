import '../widgets/ds/app_pixel_hint.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../domain/calendar/routine_calendar.dart';
import '../domain/models/routine.dart';
import '../domain/utils/repeat_days_label.dart';
import '../domain/utils/app_date_formats.dart';
import '../domain/utils/time_minutes.dart';
import '../l10n/app_localizations.dart';
import '../widgets/routine_load_failure_view.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/ds/pixel_decoration.dart';
import '../widgets/store/character_pack_scope.dart';
import '../theme/app_theme_preset.dart';
import '../theme/app_pixel_style.dart';

enum _RoutineView { list, calendar }

class RoutinesScreen extends StatefulWidget {
  const RoutinesScreen({super.key});

  @override
  State<RoutinesScreen> createState() => _RoutinesScreenState();
}

class _RoutinesScreenState extends State<RoutinesScreen> {
  _RoutineView _view = _RoutineView.list;
  DateTime? _selectedDate;
  DateTime? _visibleMonth;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_selectedDate != null) return;
    final now = context.read<RoutineAppController>().now;
    _selectedDate = DateTime(now.year, now.month, now.day);
    _visibleMonth = DateTime(now.year, now.month);
  }

  void _openAddRoutine() {
    final path = _view == _RoutineView.calendar
        ? '/routine-add?weekday=${_selectedDate!.weekday}&returnTo=routines'
        : '/routine-add?returnTo=routines';
    context.push(path);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RoutineAppController>(
      builder: (context, app, _) {
        if (app.hasBlockingLoadError) {
          return const Scaffold(body: RoutineLoadFailureView());
        }
        return Scaffold(
          bottomNavigationBar: OrbitBottomNavigation(
            currentIndex: 2,
            onHome: () => context.go('/home'),
            onProgress: () => context.go('/progress'),
            onRoutines: () {},
            onSettings: () => context.go('/settings'),
          ),
          floatingActionButton: _view == _RoutineView.list
              ? Material(
                  color: Theme.of(context).colorScheme.primary,
                  shape: AppPixelStyle.shape(),
                  // 아이콘만 있는 버튼이라 이름을 직접 준다. 없으면 스크린
                  // 리더가 «버튼»이라고만 읽고 무엇을 하는 버튼인지 알 수 없다.
                  child: Semantics(
                    button: true,
                    label: AppLocalizations.of(context).routinesAdd,
                    child: InkWell(
                      key: const Key('routine-add-button'),
                      onTap: _openAddRoutine,
                      child: const SizedBox(
                        width: 56,
                        height: 56,
                        child: Center(
                          child:
                              AppIcon(Icons.add_rounded, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
          body: AppScreenShell(
            child: app.isLoaded
                ? _RoutineContent(
                    view: _view,
                    today: DateTime(app.now.year, app.now.month, app.now.day),
                    selectedDate: _selectedDate!,
                    visibleMonth: _visibleMonth!,
                    routines: app.routines,
                    onAdd: _openAddRoutine,
                    onViewChanged: (view) => setState(() => _view = view),
                    onSelectedDateChanged: (date) => setState(() {
                      _selectedDate = date;
                      _visibleMonth = DateTime(date.year, date.month);
                    }),
                    onPreviousMonth: () => setState(() {
                      _visibleMonth =
                          RoutineCalendar.previousMonth(_visibleMonth!);
                    }),
                    onNextMonth: () => setState(() {
                      _visibleMonth = RoutineCalendar.nextMonth(_visibleMonth!);
                    }),
                  )
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
          ),
        );
      },
    );
  }
}

class _RoutineContent extends StatelessWidget {
  const _RoutineContent({
    required this.view,
    required this.today,
    required this.selectedDate,
    required this.visibleMonth,
    required this.routines,
    required this.onAdd,
    required this.onViewChanged,
    required this.onSelectedDateChanged,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final _RoutineView view;
  final DateTime today;
  final DateTime selectedDate;
  final DateTime visibleMonth;
  final List<Routine> routines;
  final VoidCallback onAdd;
  final ValueChanged<_RoutineView> onViewChanged;
  final ValueChanged<DateTime> onSelectedDateChanged;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return ListView(
      // 마지막 항목이 FAB(56 + 여백) 아래로 숨지 않도록 하단 여백을 넉넉히 둔다.
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 96),
      children: [
        _RoutinesHeader(today: today),
        const SizedBox(height: 18),
        _ViewSwitcher(value: view, onChanged: onViewChanged),
        const SizedBox(height: 22),
        if (view == _RoutineView.list)
          _RoutineList(routines: routines)
        else
          _CalendarRoutineView(
            today: today,
            visibleMonth: visibleMonth,
            selectedDate: selectedDate,
            routines: routines,
            onDateSelected: onSelectedDateChanged,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
            onAdd: onAdd,
          ),
      ],
    );
  }
}

class _RoutinesHeader extends StatelessWidget {
  const _RoutinesHeader({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final garden = CharacterPackScope.currentOf(context).id == 'poodle_garden';
    final l10n = AppLocalizations.of(context);
    final header = CatMenuHeader(
      caption: AppDateFormats.monthDayWeekday(context, today),
      title: l10n.routinesTitle,
      subtitle: l10n.routinesSubtitle,
      pose: CatPose.focus,
      catKey: const Key('routines-menu-cat'),
      decorationAsset: garden ? null : 'assets/decorations/routines-sky.png',
      decorationKey: garden ? null : const Key('routines-sky-decoration'),
    );
    if (!garden) return header;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxWidth < 300 ||
          MediaQuery.textScalerOf(context).scale(16) > 20;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          if (!compact) ...[
            const Positioned(
              left: -4,
              top: -17,
              child: GardenLeaf(
                key: Key('routines-garden-leaf-left'),
                size: 26,
                mirror: true,
                angle: -0.3,
              ),
            ),
            const Positioned(
              left: 96,
              top: -9,
              child: PixelDecoration(
                key: Key('routines-garden-daisy-left'),
                asset: 'garden-daisy',
                size: 27,
              ),
            ),
            const Positioned(
              right: 146,
              top: 11,
              child: GardenLeaf(size: 22, angle: -0.5),
            ),
            const Positioned(
              right: 76,
              top: -15,
              child: PixelSpark(size: 12, color: Color(0xFFFFB740)),
            ),
            const Positioned(
              right: 7,
              top: -22,
              child: GardenLeaf(
                key: Key('routines-garden-leaf-right'),
                size: 25,
                angle: -0.4,
              ),
            ),
            const Positioned(
              right: -5,
              top: 3,
              child: PixelDecoration(
                key: Key('routines-garden-daisy-right'),
                asset: 'garden-daisy',
                size: 25,
              ),
            ),
            const Positioned(
              right: 5,
              top: 59,
              child: PixelSpark(size: 12, color: Color(0xFFFFB740)),
            ),
            const Positioned(
              right: 107,
              bottom: 8,
              child: GardenLeaf(size: 20, angle: 0.4),
            ),
            const Positioned(
              right: 91,
              bottom: -8,
              child: PixelDecoration(
                key: Key('routines-garden-daisy-bottom'),
                asset: 'garden-daisy',
                size: 23,
              ),
            ),
          ] else ...[
            const Positioned(
              right: 95,
              top: 0,
              child: GardenLeaf(
                key: Key('routines-garden-leaf-left'),
                size: 22,
              ),
            ),
            const Positioned(
              right: 0,
              top: -10,
              child: GardenLeaf(
                key: Key('routines-garden-leaf-right'),
                size: 22,
              ),
            ),
            const Positioned(
              right: 84,
              top: 55,
              child: PixelDecoration(
                key: Key('routines-garden-daisy-bottom'),
                asset: 'garden-daisy',
                size: 22,
              ),
            ),
          ],
          header,
        ],
      );
    });
  }
}

class _ViewSwitcher extends StatelessWidget {
  const _ViewSwitcher({required this.value, required this.onChanged});

  final _RoutineView value;
  final ValueChanged<_RoutineView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 트랙 52 - 안쪽 여백 8 = 각 칸 44. UI_STANDARDS 5의 터치 타깃 최소 높이다.
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.all(2),
      decoration: ShapeDecoration(
        color: CharacterPackScope.currentOf(context).id == 'poodle_garden'
            ? context.appTheme.preset.selectedSurface
            : AppColors.orbitSurfaceSoft,
        shape: AppPixelStyle.shape(),
      ),
      // stretch가 없으면 각 칸이 내용 높이(약 19)로만 잡힌다. 선택된 흰 pill이
      // 트랙 가운데 떠 있는 것처럼 보이고, 무엇보다 위아래 절반이 눌리지 않는다.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ViewSwitchButton(
            label: AppLocalizations.of(context).routinesViewList,
            icon: Icons.format_list_bulleted_rounded,
            selected: value == _RoutineView.list,
            onTap: () => onChanged(_RoutineView.list),
          ),
          _ViewSwitchButton(
            label: AppLocalizations.of(context).routinesViewCalendar,
            icon: Icons.calendar_month_rounded,
            selected: value == _RoutineView.calendar,
            onTap: () => onChanged(_RoutineView.calendar),
          ),
        ],
      ),
    );
  }
}

class _ViewSwitchButton extends StatelessWidget {
  const _ViewSwitchButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.zero,
        child: InkWell(
          key: Key('routine-view-$label'),
          onTap: onTap,
          borderRadius: BorderRadius.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIcon(
                  icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption.copyWith(
                      color: selected ? Colors.white : AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    if (routines.isEmpty) return const _EmptyRoutines();
    return Column(
      children: routines
          .map(
            (routine) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AppRoutineRow(
                color: routine.color,
                icon: routine.iconId,
                title: routine.title,
                subtitle: TimeMinutes.formatRange(
                  routine.startMinutesFromMidnight,
                  routine.endMinutesFromMidnight,
                ),
                // 목록에서 '매일'인지 '평일'인지 알 수 없으면
                // 카드를 열어봐야만 판단할 수 있다.
                subtitleBadge:
                    RepeatDaysLabel.of(context, routine.repeatWeekdays),
                onTap: () => context.push(
                  '/routine-add?id=${routine.id}&returnTo=routines',
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarRoutineView extends StatelessWidget {
  const _CalendarRoutineView({
    required this.today,
    required this.visibleMonth,
    required this.selectedDate,
    required this.routines,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onAdd,
  });

  final DateTime today;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<Routine> routines;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedRoutines = RoutineCalendar.routinesForDate(
      selectedDate,
      routines,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _MonthCalendar(
          today: today,
          visibleMonth: visibleMonth,
          selectedDate: selectedDate,
          routines: routines,
          onDateSelected: onDateSelected,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
        ),
        const SizedBox(height: 24),
        // 개수는 제목 바로 옆에 둔다. 오른쪽 끝은 FAB이 가린다.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                _dateLabel(context, selectedDate),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSection,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)
                  .routineCount(selectedRoutines.length),
              style: AppTextStyles.caption,
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (selectedRoutines.isEmpty)
          const _SelectedDateEmpty()
        else
          // 목록 탭과 같은 줄을 쓴다. 예전에는 캘린더만 루틴 색을 배경
          // 틴트로 칠하고 왼쪽에 시각·점 레일을 따로 뒀는데, 통합 줄이
          // 색 원과 시간을 모두 갖고 있어 레일이 같은 말을 반복했다.
          _RoutineList(routines: selectedRoutines),
        const SizedBox(height: 16),
        AppButton(
          key: const Key('calendar-add-routine-button'),
          label: l10n.homeAddRoutine,
          icon: Icons.add_rounded,
          onPressed: onAdd,
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.today,
    required this.visibleMonth,
    required this.selectedDate,
    required this.routines,
    required this.onDateSelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final DateTime today;
  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<Routine> routines;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    final days = RoutineCalendar.monthGridDates(visibleMonth);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: appSurfaceDecoration(
        radius: 24,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: AppLocalizations.of(context).routinesPrevMonth,
                onPressed: onPreviousMonth,
                icon: const AppIcon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  AppDateFormats.yearMonth(context, visibleMonth),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleSection,
                ),
              ),
              IconButton(
                tooltip: AppLocalizations.of(context).routinesNextMonth,
                onPressed: onNextMonth,
                icon: const AppIcon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var weekday = DateTime.monday;
                  weekday <= DateTime.sunday;
                  weekday++)
                _WeekdayHeader(
                  AppDateFormats.weekdayNarrowByIndex(context, weekday),
                  weekend: weekday >= DateTime.saturday,
                ),
            ],
          ),
          const SizedBox(height: 5),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              // 날짜 원(31) + 간격(3) + 점(5) + 상하 패딩(8)이 들어갈 높이.
              childAspectRatio: .86,
            ),
            itemBuilder: (context, index) {
              final day = days[index];
              return _CalendarDateCell(
                date: day,
                visibleMonth: visibleMonth,
                selected: RoutineCalendar.sameDate(day, selectedDate),
                isToday: RoutineCalendar.sameDate(day, today),
                routines: RoutineCalendar.routinesForDate(day, routines),
                onTap: () => onDateSelected(day),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader(this.label, {this.weekend = false});

  final String label;
  final bool weekend;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              color: weekend ? AppColors.dangerText : AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

class _CalendarDateCell extends StatelessWidget {
  const _CalendarDateCell({
    required this.date,
    required this.visibleMonth,
    required this.selected,
    required this.isToday,
    required this.routines,
    required this.onTap,
  });

  final DateTime date;
  final DateTime visibleMonth;
  final bool selected;
  final bool isToday;
  final List<Routine> routines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final inMonth = date.month == visibleMonth.month;
    final weekend = date.weekday >= DateTime.saturday;
    final count = routines.length;
    return Semantics(
      button: true,
      selected: selected,
      label: '${AppDateFormats.monthDay(context, date)}'
          '${isToday ? AppLocalizations.of(context).routinesDaySemanticToday : ''}'
          '${AppLocalizations.of(context).routinesDaySemanticCount(count)}',
      child: InkWell(
        key: Key('calendar-day-${date.year}-${date.month}-${date.day}'),
        onTap: onTap,
        borderRadius: BorderRadius.zero,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              Container(
                width: 31,
                height: 31,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.rectangle,
                  // 다른 달로 넘어가도 '오늘'을 잃지 않도록 선택과 별개로 표시한다.
                  border: !selected && isToday
                      ? Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1.5,
                        )
                      : null,
                ),
                child: Text(
                  '${date.day}',
                  style: AppTextStyles.caption.copyWith(
                    color: selected
                        ? Colors.white
                        : !inMonth
                            ? AppColors.textMuted.withValues(alpha: .45)
                            : weekend
                                ? AppColors.dangerText
                                : AppColors.textPrimary,
                    fontWeight:
                        selected || isToday ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // 셀에는 '무엇이 있는지'만 색으로 남긴다.
              // 정확한 개수는 아래 날짜 헤더에서 글자로 읽는 편이 낫다.
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: routines
                      .take(3)
                      .map(
                        (routine) => Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: inMonth
                                ? routine.color
                                : routine.color.withValues(alpha: .26),
                            shape: BoxShape.rectangle,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedDateEmpty extends StatelessWidget {
  const _SelectedDateEmpty();

  @override
  Widget build(BuildContext context) {
    return AppPixelHint(
      title: AppLocalizations.of(context).routinesNoneForDay,
      message: AppLocalizations.of(context).routinesNoneForDayHint,
    );
  }
}

class _EmptyRoutines extends StatelessWidget {
  const _EmptyRoutines();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56),
      child: Center(
        child: AppPixelHint(
            message: AppLocalizations.of(context).routinesAddFirst),
      ),
    );
  }
}

String _dateLabel(BuildContext context, DateTime date) =>
    AppDateFormats.monthDayWeekday(context, date);
