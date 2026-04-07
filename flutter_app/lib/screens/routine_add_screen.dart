import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_scaffold_messenger.dart';
import '../application/routine_app_controller.dart';
import '../data/routine_form_palette.dart';
import '../domain/models/routine.dart';
import '../domain/routine_overlap/routine_schedule_overlap.dart';
import '../domain/utils/time_minutes.dart';
import '../domain/validation/routine_form_validator.dart';
import '../theme/home_theme.dart';
import '../widgets/ds/ds.dart';
import '../widgets/form/pastel_color_palette.dart';
import '../widgets/form/pastel_switch_tile.dart';
import '../widgets/form/pastel_text_field.dart';
import '../widgets/form/pastel_time_field.dart';
import '../widgets/form/pastel_weekday_selector.dart';
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

  @override
  Widget build(BuildContext context) {
    final title = _isEdit ? '루틴 편집' : '루틴 추가';
    final repeat = _selectedRepeatDays();
    final candidate = _routineFromForm();
    final controller = context.watch<RoutineAppController>();
    final conflicts = RoutineScheduleOverlap.conflictingRoutines(
      candidate: candidate,
      allRoutines: controller.routines,
      excludeRoutineId: _isEdit ? candidate.id : null,
    );

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: HomeTheme.pageGradient),
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
                  gradient: HomeTheme.shellGradient,
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
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      PastelTextField(
                                        label: '루틴 이름',
                                        hint: '예: 아침 스트레칭',
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                        onChanged: _validateTitle,
                                        errorText: _titleError,
                                        helperText: '홈 화면과 알림에 표시될 이름이에요.',
                                      ),
                                      const SizedBox(height: 20),
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
                                                  onChanged: (t) => setState(() {
                                                    _startTime = t;
                                                    _timeError = _timeRangeError();
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
                                                  onChanged: (t) => setState(() {
                                                    _endTime = t;
                                                    _timeError = _timeRangeError();
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
                                    helperText:
                                        '루틴을 반복할 요일을 1개 이상 골라주세요.',
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelSwitchTile(
                                    title: '알림 받기',
                                    subtitle: '설정한 시간에 알림을 보내드릴게요',
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
                                                '"${conflicts.first.title}" 루틴과 시간이 겹쳐요. 저장은 가능하지만 홈 화면이 복잡해질 수 있어요.',
                                                style: AppTextStyles.caption
                                                    .copyWith(height: 1.45),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
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
