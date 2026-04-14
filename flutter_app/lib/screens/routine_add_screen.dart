import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold_messenger.dart';
import '../application/mappers/home_view_mapper.dart';
import '../application/routine_app_controller.dart';
import '../data/routine_form_palette.dart';
import '../domain/models/routine.dart';
import '../domain/routine_overlap/routine_schedule_overlap.dart';
import '../domain/utils/time_minutes.dart';
import '../domain/validation/routine_form_validator.dart';
import '../models/home_models.dart';
import '../theme/home_theme.dart';
import '../theme/app_theme_preset.dart';
import '../widgets/ds/ds.dart';
import '../widgets/form/pastel_color_palette.dart';
import '../widgets/form/pastel_switch_tile.dart';
import '../widgets/form/pastel_text_field.dart';
import '../widgets/form/pastel_time_field.dart';
import '../widgets/form/pastel_weekday_selector.dart';
import '../widgets/home/circular_timetable_area.dart';
import '../widgets/home/home_decorative_background.dart';

/// 루틴 추가·편집 — 저장은 [RoutineAppController.saveRoutine]
class RoutineAddScreen extends StatefulWidget {
  const RoutineAddScreen({super.key, this.editRoutineId});

  /// 쿼리 `?id=` — 있으면 해당 루틴 편집
  final String? editRoutineId;

  @override
  State<RoutineAddScreen> createState() => _RoutineAddScreenState();
}

class _RoutineAddScreenState extends State<RoutineAddScreen> {
  final _nameController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);

  /// 월~일 선택
  late List<bool> _weekdays;

  /// 저장·편집에 쓰는 ARGB (팔레트와 독립적으로 유지 — 불일치 시에도 기존 색 보존)
  late int _selectedColorArgb;

  bool _notificationEnabled = true;
  String? _titleError;
  String? _timeError;
  String? _repeatError;
  int? _previewWeekday;
  bool _isDeleting = false;

  Routine? _editingBaseline;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  bool get _isEdit => widget.editRoutineId != null;

  @override
  void initState() {
    super.initState();
    _weekdays = [true, true, true, true, true, false, false];
    _selectedColorArgb = routineColorArgbNormalize(
      routineFormPaletteColors[3].toARGB32(),
    );
    _previewWeekday = _firstSelectedWeekday(_weekdays);
    if (widget.editRoutineId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEditRoutine());
    }
  }

  Future<void> _loadEditRoutine() async {
    final controller = context.read<RoutineAppController>();
    if (!controller.isLoaded) {
      await controller.load();
    }
    if (!mounted) return;
    final id = widget.editRoutineId!;
    Routine? found;
    for (final r in controller.routines) {
      if (r.id == id) {
        found = r;
        break;
      }
    }
    if (found == null) return;
    final r = found;
    final normalizedArgb = routineColorArgbNormalize(r.colorValue);
    setState(() {
      _editingBaseline = r;
      _nameController.text = r.title;
      _startTime = TimeOfDay(
        hour: r.startMinutesFromMidnight ~/ 60,
        minute: r.startMinutesFromMidnight % 60,
      );
      _endTime = TimeOfDay(
        hour: r.endMinutesFromMidnight ~/ 60,
        minute: r.endMinutesFromMidnight % 60,
      );
      for (var i = 0; i < 7; i++) {
        _weekdays[i] = r.repeatWeekdays.contains(i + 1);
      }
      _previewWeekday = _firstSelectedWeekday(_weekdays);
      _selectedColorArgb = normalizedArgb;
      _notificationEnabled = r.notificationEnabled;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onWeekdayChanged(int index, bool value) {
    setState(() {
      _weekdays[index] = value;
      _repeatError = _repeatDaysError();
      _previewWeekday = _normalizedPreviewWeekday(
        selectedWeekdays: _selectedRepeatDays(),
        fallbackWeekday: value ? index + 1 : _previewWeekday,
      );
    });
  }

  void _validateTitle(String value) {
    setState(() {
      _titleError = _titleValidationError(value);
    });
  }

  String? _titleValidationError(String value) =>
      RoutineFormValidator.validateTitle(value);

  String? _timeRangeError() => RoutineFormValidator.validateTimeRange(
        TimeMinutes.fromTimeOfDay(_startTime),
        TimeMinutes.fromTimeOfDay(_endTime),
      );

  String? _repeatDaysError() =>
      RoutineFormValidator.validateRepeatDays(_selectedRepeatDays());

  /// 현재 [_selectedColorArgb]와 일치하는 팔레트 칸. 없으면 null.
  int? _paletteIndexForUi() {
    final n = routineColorArgbNormalize(_selectedColorArgb);
    final i = routineFormPaletteColors.indexWhere(
      (c) => routineColorArgbNormalize(c.toARGB32()) == n,
    );
    return i >= 0 ? i : null;
  }

  Routine _routineFromForm() {
    final title = _nameController.text;
    final colorValue = routineColorArgbNormalize(_selectedColorArgb);
    final repeat = <int>{};
    for (var i = 0; i < 7; i++) {
      if (_weekdays[i]) repeat.add(i + 1);
    }

    if (_isEdit && _editingBaseline != null) {
      final b = _editingBaseline!;
      return b.copyWith(
        title: title.trim(),
        startMinutesFromMidnight: TimeMinutes.fromTimeOfDay(_startTime),
        endMinutesFromMidnight: TimeMinutes.fromTimeOfDay(_endTime),
        repeatWeekdays: repeat,
        colorValue: colorValue,
        notificationEnabled: _notificationEnabled,
      );
    }

    return Routine.create(
      title: title,
      startTime: _startTime,
      endTime: _endTime,
      repeatWeekdays: repeat,
      colorValue: colorValue,
      notificationEnabled: _notificationEnabled,
    );
  }

  Set<int> _selectedRepeatDays() {
    final repeat = <int>{};
    for (var i = 0; i < 7; i++) {
      if (_weekdays[i]) repeat.add(i + 1);
    }
    return repeat;
  }

  String _repeatSummary(Set<int> repeat) {
    if (repeat.length == 7) return '매일 반복';
    const weekdays = {1, 2, 3, 4, 5};
    const weekend = {6, 7};
    if (repeat.containsAll(weekdays) && repeat.length == weekdays.length) {
      return '평일 반복';
    }
    if (repeat.containsAll(weekend) && repeat.length == weekend.length) {
      return '주말 반복';
    }

    final labels = <String>[];
    for (var i = 0; i < 7; i++) {
      if (_weekdays[i]) labels.add(_weekdayLabels[i]);
    }
    return labels.join(', ');
  }

  String _timeSummary() {
    final startLabel = _startTime.format(context);
    final endLabel = _endTime.format(context);
    return '$startLabel - $endLabel';
  }

  static int? _firstSelectedWeekday(List<bool> weekdays) {
    for (var i = 0; i < weekdays.length; i++) {
      if (weekdays[i]) return i + 1;
    }
    return null;
  }

  static int? _normalizedPreviewWeekday({
    required Set<int> selectedWeekdays,
    required int? fallbackWeekday,
  }) {
    if (selectedWeekdays.isEmpty) return null;
    if (fallbackWeekday != null && selectedWeekdays.contains(fallbackWeekday)) {
      return fallbackWeekday;
    }
    final sorted = selectedWeekdays.toList()..sort();
    return sorted.first;
  }

  Future<void> _saveAfterValidation() async {
    FocusScope.of(context).unfocus();

    final title = _nameController.text;
    final startMin = TimeMinutes.fromTimeOfDay(_startTime);
    final endMin = TimeMinutes.fromTimeOfDay(_endTime);
    final repeat = <int>{};
    for (var i = 0; i < 7; i++) {
      if (_weekdays[i]) repeat.add(i + 1);
    }

    final titleError = _titleValidationError(title);
    final timeError = RoutineFormValidator.validateTimeRange(startMin, endMin);
    final repeatError = RoutineFormValidator.validateRepeatDays(repeat);

    setState(() {
      _titleError = titleError;
      _timeError = timeError;
      _repeatError = repeatError;
    });

    final error = titleError ?? timeError ?? repeatError;
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('입력한 값을 확인해주세요.')),
      );
      return;
    }

    if (widget.editRoutineId != null && _editingBaseline == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('편집할 루틴을 찾을 수 없어요.')),
      );
      return;
    }

    final candidate = _routineFromForm();
    final controller = context.read<RoutineAppController>();

    final conflicts = RoutineScheduleOverlap.conflictingRoutines(
      candidate: candidate,
      allRoutines: controller.routines,
      excludeRoutineId: _isEdit ? candidate.id : null,
    );
    if (conflicts.isNotEmpty) {
      if (!mounted) return;
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('시간 겹침'),
          content: const Text(
            '이 시간대에는 다른 루틴과 겹쳐요. 그래도 저장할까요?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('시간 다시 조정'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('그래도 저장'),
            ),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }

    final result = await controller.saveRoutine(candidate);
    if (!mounted) return;
    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? '저장에 실패했어요.')),
      );
      return;
    }
    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('루틴을 저장했어요')),
    );
    context.go('/home');
  }

  Future<void> handleSave() => _saveAfterValidation();

  Future<void> _handleDelete() async {
    if (!_isEdit || _editingBaseline == null || _isDeleting) return;

    FocusScope.of(context).unfocus();
    final routine = _editingBaseline!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text(
          '"${routine.title}" 루틴과 관련 기록을 삭제할까요?\n이 작업은 되돌릴 수 없어요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted) return;

    setState(() => _isDeleting = true);
    final result =
        await context.read<RoutineAppController>().deleteRoutine(routine.id);
    if (!mounted) return;
    setState(() => _isDeleting = false);

    if (!result.ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.errorMessage ?? '삭제에 실패했어요.')),
      );
      return;
    }

    appScaffoldMessengerKey.currentState?.showSnackBar(
      const SnackBar(content: Text('루틴을 삭제했어요')),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? '루틴 편집' : '루틴 추가';
    final repeat = _selectedRepeatDays();
    final candidate = _routineFromForm();
    final controller = context.watch<RoutineAppController>();
    final theme = context.appTheme;
    final isNameFilled = _nameController.text.trim().isNotEmpty;
    final isTimeValid = _timeRangeError() == null;
    final isRepeatValid = _repeatDaysError() == null;
    final conflicts = RoutineScheduleOverlap.conflictingRoutines(
      candidate: candidate,
      allRoutines: controller.routines,
      excludeRoutineId: _isEdit ? candidate.id : null,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: theme.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(maxWidth: HomeTheme.mobileWidth),
              child: Container(
                margin: const EdgeInsets.all(16),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(HomeTheme.shellRadius),
                  gradient: theme.shellGradient,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Positioned.fill(child: HomeDecorativeBackground()),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppPageHeader(
                          title: title,
                          onBack: () => context.pop(),
                          trailing: _isEdit
                              ? IconButton(
                                  onPressed: _isDeleting ? null : _handleDelete,
                                  tooltip: '루틴 삭제',
                                  icon: _isDeleting
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.warning
                                              .withValues(alpha: 0.92),
                                        ),
                                )
                              : null,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppCard(
                                  variant: AppCardVariant.elevated,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '시간 설정',
                                        style: AppTextStyles.titleSection
                                            .copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '하루 원형 일정표에서 가장 중요한 기준이에요.',
                                        style: AppTextStyles.caption
                                            .copyWith(height: 1.35),
                                      ),
                                      const SizedBox(height: 16),
                                      LayoutBuilder(
                                        builder: (context, constraints) {
                                          final gap = constraints.maxWidth < 340
                                              ? 8.0
                                              : 12.0;
                                          return Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: PastelTimeField(
                                                  label: '시작',
                                                  value: _startTime,
                                                  onChanged: (t) =>
                                                      setState(() {
                                                    _startTime = t;
                                                    _timeError =
                                                        _timeRangeError();
                                                  }),
                                                  errorText: _timeError,
                                                  helperText:
                                                      '루틴이 시작되는 시간을 선택하세요.',
                                                ),
                                              ),
                                              SizedBox(width: gap),
                                              Expanded(
                                                child: PastelTimeField(
                                                  label: '종료',
                                                  value: _endTime,
                                                  onChanged: (t) =>
                                                      setState(() {
                                                    _endTime = t;
                                                    _timeError =
                                                        _timeRangeError();
                                                  }),
                                                  errorText: _timeError,
                                                  helperText:
                                                      '시작 시간보다 늦게 설정해야 해요.',
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelWeekdaySelector(
                                    labels: _weekdayLabels,
                                    selected: _weekdays,
                                    onChanged: _onWeekdayChanged,
                                    errorText: _repeatError,
                                    helperText: '루틴을 반복할 요일을 1개 이상 골라주세요.',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  variant: AppCardVariant.elevated,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '기본 정보',
                                        style: AppTextStyles.titleSection
                                            .copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 16),
                                      PastelTextField(
                                        label: '루틴 이름',
                                        hint: '예: 아침 스트레칭',
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        onChanged: _validateTitle,
                                        errorText: _titleError,
                                        helperText: '홈 화면과 알림에 표시될 이름이에요.',
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelColorPalette(
                                    colors: routineFormPaletteColors,
                                    selectedIndex: _paletteIndexForUi(),
                                    onSelected: (i) => setState(() {
                                      _selectedColorArgb =
                                          routineColorArgbNormalize(
                                        routineFormPaletteColors[i].toARGB32(),
                                      );
                                    }),
                                    helperText:
                                        '선택한 색은 홈 카드와 원형 일정표에서 이 루틴을 구분하는 기준이 돼요.',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelSwitchTile(
                                    title: '알림 받기',
                                    subtitle: '루틴 시작 시각에 맞춰 1회 알려드릴게요',
                                    helper: '알림을 받으면 바로 완료하거나 잠시 미룰 수 있어요.',
                                    value: _notificationEnabled,
                                    onChanged: (v) => setState(
                                        () => _notificationEnabled = v),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  variant: AppCardVariant.elevated,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        '입력 미리보기',
                                        style: AppTextStyles.titleSection
                                            .copyWith(fontSize: 16),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          _FormProgressChip(
                                            label: '이름',
                                            done: isNameFilled,
                                          ),
                                          _FormProgressChip(
                                            label: '시간',
                                            done: isTimeValid,
                                          ),
                                          _FormProgressChip(
                                            label: '요일',
                                            done: isRepeatValid,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: Color(_selectedColorArgb),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      Color(_selectedColorArgb)
                                                          .withValues(
                                                              alpha: 0.28),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              _nameController.text
                                                      .trim()
                                                      .isEmpty
                                                  ? '루틴 이름을 입력하면 여기서 바로 확인할 수 있어요'
                                                  : _nameController.text.trim(),
                                              style: AppTextStyles.bodyStrong,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      _SummaryLine(
                                        icon: Icons.schedule_rounded,
                                        text:
                                            '${_timeSummary()} · ${_repeatSummary(repeat)}',
                                      ),
                                      const SizedBox(height: 8),
                                      _SummaryLine(
                                        icon: _notificationEnabled
                                            ? Icons.notifications_active_rounded
                                            : Icons.notifications_off_rounded,
                                        text: _notificationEnabled
                                            ? '루틴 시작 시간에 알림을 보낼 예정이에요'
                                            : '알림 없이 루틴만 기록해둘게요',
                                      ),
                                      if (conflicts.isNotEmpty) ...[
                                        const SizedBox(height: 14),
                                        Container(
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: AppColors
                                                .highlightGradient.colors.first
                                                .withValues(alpha: 0.32),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: AppColors.warning
                                                  .withValues(alpha: 0.45),
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '시간 겹침 주의',
                                                style: AppTextStyles.bodyStrong
                                                    .copyWith(fontSize: 14),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '"${conflicts.first.title}"과 시간이 겹쳐 홈에서 어떤 루틴이 먼저 보일지 헷갈릴 수 있어요.',
                                                style: AppTextStyles.caption
                                                    .copyWith(height: 1.45),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 16),
                                      _RoutineSchedulePreview(
                                        candidate: candidate,
                                        allRoutines: controller.routines,
                                        isEdit: _isEdit,
                                        selectedWeekday:
                                            _normalizedPreviewWeekday(
                                          selectedWeekdays: repeat,
                                          fallbackWeekday: _previewWeekday,
                                        ),
                                        onWeekdaySelected: (weekday) {
                                          setState(
                                              () => _previewWeekday = weekday);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_isEdit) ...[
                                  AppButton(
                                    label: '루틴 삭제',
                                    icon: Icons.delete_outline_rounded,
                                    onPressed:
                                        _isDeleting ? null : _handleDelete,
                                    variant: AppButtonVariant.destructive,
                                    isLoading: _isDeleting,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                AppButton(
                                  label: '저장하기',
                                  icon: Icons.check_rounded,
                                  onPressed: handleSave,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineSchedulePreview extends StatelessWidget {
  const _RoutineSchedulePreview({
    required this.candidate,
    required this.allRoutines,
    required this.isEdit,
    required this.selectedWeekday,
    required this.onWeekdaySelected,
  });

  final Routine candidate;
  final List<Routine> allRoutines;
  final bool isEdit;
  final int? selectedWeekday;
  final ValueChanged<int> onWeekdaySelected;

  @override
  Widget build(BuildContext context) {
    final weekdays = candidate.repeatWeekdays.toList()..sort();
    if (weekdays.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.52),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: AppColors.border.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '요일별 미리보기',
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '요일을 선택하면 하루 기준으로 원형 일정표를 바로 보여드릴게요.',
              style: AppTextStyles.caption.copyWith(height: 1.4),
            ),
          ],
        ),
      );
    }

    final weekday =
        selectedWeekday != null && weekdays.contains(selectedWeekday)
            ? selectedWeekday!
            : weekdays.first;
    final label = _weekdayName(weekday);
    final selectedCount = candidate.repeatWeekdays.length;
    final previewRoutines = [
      ...allRoutines.where(
        (routine) =>
            routine.id != candidate.id &&
            routine.repeatWeekdays.contains(weekday),
      ),
      candidate,
    ]..sort(
        (a, b) => a.startMinutesFromMidnight.compareTo(
          b.startMinutesFromMidnight,
        ),
      );

    final dayConflicts = allRoutines
        .where(
          (routine) =>
              routine.id != candidate.id &&
              routine.repeatWeekdays.contains(weekday) &&
              !(routine.endMinutesFromMidnight <=
                      candidate.startMinutesFromMidnight ||
                  routine.startMinutesFromMidnight >=
                      candidate.endMinutesFromMidnight),
        )
        .toList();

    final segments = previewRoutines
        .map(
          (routine) => RoutineSegment(
            id: routine.id,
            startMinutesFromMidnight: routine.startMinutesFromMidnight,
            endMinutesFromMidnight: routine.endMinutesFromMidnight,
            label: routine.title,
            emoji: routine.id == candidate.id ? '✨' : routine.iconEmoji,
            color: routine.id == candidate.id
                ? candidate.color.withValues(alpha: 0.98)
                : routine.color.withValues(alpha: 0.56),
          ),
        )
        .toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: candidate.color.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: candidate.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '요일별 미리보기',
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
                ),
              ),
              if (selectedCount > 1)
                AppStatusBadge(
                  label: '$selectedCount일 반복',
                  tone: AppStatusBadgeTone.info,
                ),
              if (isEdit)
                const AppStatusBadge(
                  label: '편집 중',
                  tone: AppStatusBadgeTone.info,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '선택한 요일에 따라 하루 일정표가 달라져요. 원하는 요일을 눌러서 직접 확인해보세요.',
            style: AppTextStyles.caption.copyWith(height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: weekdays
                .map(
                  (day) => _PreviewWeekdayChip(
                    label: _weekdayShortName(day),
                    isSelected: day == weekday,
                    color: candidate.color,
                    onTap: () => onWeekdaySelected(day),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PreviewInfoCard(
                  label: '기준 요일',
                  value: label,
                  tone: candidate.color.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PreviewInfoCard(
                  label: '그날 루틴 수',
                  value: '${previewRoutines.length}개',
                  tone: const Color(0xFFEFF4FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PreviewInfoCard(
                  label: '겹침',
                  value:
                      dayConflicts.isEmpty ? '없음' : '${dayConflicts.length}개',
                  tone: dayConflicts.isEmpty
                      ? const Color(0xFFEAF7ED)
                      : const Color(0xFFFFF2D8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  candidate.color.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.82),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: candidate.color.withValues(alpha: 0.22),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$label 일정 배치',
                            style:
                                AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${TimeOfDay(hour: candidate.startMinutesFromMidnight ~/ 60, minute: candidate.startMinutesFromMidnight % 60).format(context)} - ${TimeOfDay(hour: candidate.endMinutesFromMidnight ~/ 60, minute: candidate.endMinutesFromMidnight % 60).format(context)}',
                            style: AppTextStyles.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textMuted.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: candidate.color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        candidate.title.isEmpty ? '새 루틴' : candidate.title,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Center(
                  child: CircularTimetableArea(
                    routines: segments,
                    currentTime: TimeOfDay(
                      hour: candidate.startMinutesFromMidnight ~/ 60,
                      minute: candidate.startMinutesFromMidnight % 60,
                    ),
                    activeRoutine:
                        HomeViewMapper.ringStubFromRoutine(candidate),
                    centerRoutineName:
                        candidate.title.isEmpty ? '새 루틴' : candidate.title,
                    size: 228,
                  ),
                ),
                const SizedBox(height: 14),
                _PreviewDayScheduleList(
                  weekdayLabel: label,
                  candidateId: candidate.id,
                  routines: previewRoutines,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (dayConflicts.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5DE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                '$label에는 "${dayConflicts.first.title}"과 시간이 겹쳐요. 이 요일의 홈 화면에서는 어떤 루틴이 먼저 보여야 할지 다시 확인하는 편이 좋습니다.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF9F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFA6D1B0).withValues(alpha: 0.7),
                ),
              ),
              child: Text(
                '$label 일정에서는 새 루틴이 자연스럽게 들어갑니다. 홈에서도 이 요일 기준 흐름이 그대로 반영돼요.',
                style: AppTextStyles.caption.copyWith(
                  fontSize: 13,
                  height: 1.45,
                  color: AppColors.textPrimary.withValues(alpha: 0.88),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _weekdayName(int weekday) {
    const map = {
      1: '월요일',
      2: '화요일',
      3: '수요일',
      4: '목요일',
      5: '금요일',
      6: '토요일',
      7: '일요일',
    };
    return map[weekday] ?? '선택한 요일';
  }

  String _weekdayShortName(int weekday) {
    const map = {
      1: '월',
      2: '화',
      3: '수',
      4: '목',
      5: '금',
      6: '토',
      7: '일',
    };
    return map[weekday] ?? '';
  }
}

class _PreviewWeekdayChip extends StatelessWidget {
  const _PreviewWeekdayChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.94),
                    color.withValues(alpha: 0.16),
                    const Color(0xFFE8DDFA).withValues(alpha: 0.28),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.42)
                : AppColors.border.withValues(alpha: 0.5),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewDayScheduleList extends StatelessWidget {
  const _PreviewDayScheduleList({
    required this.weekdayLabel,
    required this.candidateId,
    required this.routines,
  });

  final String weekdayLabel;
  final String candidateId;
  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.view_timeline_rounded,
                size: 16,
                color: AppColors.textMuted.withValues(alpha: 0.84),
              ),
              const SizedBox(width: 6),
              Text(
                '$weekdayLabel 일정 순서',
                style: AppTextStyles.bodyStrong.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(routines.length, (index) {
            final routine = routines[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == routines.length - 1 ? 0 : 8,
              ),
              child: _PreviewScheduleRow(
                routine: routine,
                isCandidate: routine.id == candidateId,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PreviewScheduleRow extends StatelessWidget {
  const _PreviewScheduleRow({
    required this.routine,
    required this.isCandidate,
  });

  final Routine routine;
  final bool isCandidate;

  @override
  Widget build(BuildContext context) {
    final start = TimeOfDay(
      hour: routine.startMinutesFromMidnight ~/ 60,
      minute: routine.startMinutesFromMidnight % 60,
    ).format(context);
    final end = TimeOfDay(
      hour: routine.endMinutesFromMidnight ~/ 60,
      minute: routine.endMinutesFromMidnight % 60,
    ).format(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: isCandidate
            ? routine.color.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCandidate
              ? routine.color.withValues(alpha: 0.32)
              : AppColors.border.withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: routine.color.withValues(alpha: isCandidate ? 0.95 : 0.7),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        routine.title.isEmpty ? '이름 없는 루틴' : routine.title,
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary.withValues(alpha: 0.92),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCandidate)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '새 루틴',
                          style: AppTextStyles.caption.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.86),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$start - $end',
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.textMuted.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewInfoCard extends StatelessWidget {
  const _PreviewInfoCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontSize: 11,
              color: AppColors.textMuted.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _FormProgressChip extends StatelessWidget {
  const _FormProgressChip({
    required this.label,
    required this.done,
  });

  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? const Color(0xFFDFF5E7)
            : Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done
              ? const Color(0xFFAED8BA)
              : AppColors.border.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: done ? const Color(0xFF4C8B61) : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: done ? const Color(0xFF4C8B61) : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.caption.copyWith(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textPrimary.withValues(alpha: 0.84),
            ),
          ),
        ),
      ],
    );
  }
}
