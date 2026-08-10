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
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/ds/ds.dart';
import '../widgets/form/pastel_color_palette.dart';
import '../widgets/form/pastel_switch_tile.dart';
import 'routine_add/routine_edit_status_views.dart';
import 'routine_add/routine_form_controls.dart';
import 'routine_add/routine_form_preview.dart';

/// 루틴 추가·편집 — 저장은 [RoutineAppController.saveRoutine]
class RoutineAddScreen extends StatefulWidget {
  const RoutineAddScreen({
    super.key,
    this.editRoutineId,
    this.initialWeekday,
    this.returnToRoutines = false,
  });

  /// 쿼리 `?id=` — 있으면 해당 루틴 편집
  final String? editRoutineId;

  /// 달력에서 진입했을 때 선택 날짜의 요일(월=1 … 일=7)을 미리 선택한다.
  final int? initialWeekday;

  /// 루틴 목록·달력에서 진입한 뒤 저장/삭제 시 해당 화면으로 복귀한다.
  final bool returnToRoutines;

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
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _isEditLoading = false;
  bool _editLoadFailed = false;
  bool _showMoreSettings = false;

  Routine? _editingBaseline;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  bool get _isEdit => widget.editRoutineId != null;

  @override
  void initState() {
    super.initState();
    final initialWeekday = widget.initialWeekday;
    _weekdays =
        initialWeekday != null && initialWeekday >= 1 && initialWeekday <= 7
            ? List<bool>.generate(7, (index) => index + 1 == initialWeekday)
            : [true, true, true, true, true, false, false];
    _selectedColorArgb = routineColorArgbNormalize(
      routineFormPaletteColors[3].toARGB32(),
    );
    _isEditLoading = _isEdit;
    if (_isEdit) {
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
    if (found == null) {
      setState(() {
        _editLoadFailed = true;
        _isEditLoading = false;
      });
      return;
    }
    final r = found;
    final normalizedArgb = routineColorArgbNormalize(r.colorValue);
    setState(() {
      _editLoadFailed = false;
      _isEditLoading = false;
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
    final repeat = _selectedRepeatDays();

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

  Future<void> _saveAfterValidation() async {
    if (_isSaving || _isDeleting || (_isEdit && _isEditLoading)) return;
    FocusScope.of(context).unfocus();

    final title = _nameController.text;
    final startMin = TimeMinutes.fromTimeOfDay(_startTime);
    final endMin = TimeMinutes.fromTimeOfDay(_endTime);
    final repeat = _selectedRepeatDays();

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

    setState(() => _isSaving = true);
    try {
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
      context.go(widget.returnToRoutines ? '/routines' : '/home');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

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
    context.go(widget.returnToRoutines ? '/routines' : '/home');
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RoutineAppController>();
    final isBusy = _isSaving || _isDeleting || _isEditLoading;

    if (_isEditLoading) {
      return const Scaffold(body: RoutineEditLoadingView());
    }
    if (_editLoadFailed) {
      return Scaffold(
        body: RoutineEditLoadFailedView(onBack: () => context.pop()),
      );
    }

    final candidate = _routineFromForm();
    final conflicts = RoutineScheduleOverlap.conflictingRoutines(
      candidate: candidate,
      allRoutines: controller.routines,
      excludeRoutineId: _isEdit ? candidate.id : null,
    );

    return Scaffold(
      // 저장 바는 Scaffold 기본 배경 위에 뜬다. 배경을 명시하지 않으면
      // 버튼 주변 여백이 칠해지지 않아 루트의 검정이 그대로 보인다.
      bottomNavigationBar: ColoredBox(
        color: AppColors.pageBackground,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(28, 10, 28, 16),
          child: AppButton(
            label: _isEdit ? '변경사항 저장하기' : '루틴 저장하기',
            onPressed: isBusy ? null : _saveAfterValidation,
            isLoading: _isSaving,
          ),
        ),
      ),
      body: AppScreenShell(
        child: Column(
          children: [
            RoutineFormHeader(
              title: _isEdit ? '루틴 편집' : '새 루틴',
              onBack: () => context.pop(),
              onDelete: _isEdit && !isBusy ? _handleDelete : null,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RoutineFormPreview(candidate: candidate),
                    const SizedBox(height: 22),
                    const Text('무엇을 할까요?', style: AppTextStyles.titleSection),
                    const SizedBox(height: 10),
                    RoutineFormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _nameController,
                            onChanged: _validateTitle,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.titleSection.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              hintText: '예: 아침 산책',
                              hintStyle: AppTextStyles.body.copyWith(
                                color:
                                    AppColors.textMuted.withValues(alpha: .7),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 8,
                              ),
                            ),
                          ),
                          if (_titleError != null) ...[
                            const SizedBox(height: 6),
                            AppFieldMessage(
                              message: _titleError!,
                              isError: true,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              RoutineSuggestionChip(
                                label: '아침 루틴',
                                onTap: () => _applySuggestion('아침 루틴'),
                              ),
                              RoutineSuggestionChip(
                                label: '운동',
                                onTap: () => _applySuggestion('운동'),
                              ),
                              RoutineSuggestionChip(
                                label: '독서',
                                onTap: () => _applySuggestion('독서'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('언제 할까요?', style: AppTextStyles.titleSection),
                    const SizedBox(height: 10),
                    RoutineFormSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: RoutineTimeTile(
                                  label: '시작 시간',
                                  value: _startTime,
                                  onTap: () => _pickTime(start: true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RoutineTimeTile(
                                  label: '종료 시간',
                                  value: _endTime,
                                  onTap: () => _pickTime(start: false),
                                ),
                              ),
                            ],
                          ),
                          if (_timeError != null) ...[
                            const SizedBox(height: 8),
                            AppFieldMessage(
                              message: _timeError!,
                              isError: true,
                            ),
                          ],
                          const SizedBox(height: 22),
                          const Text('반복 요일', style: AppTextStyles.label),
                          const SizedBox(height: 12),
                          Row(
                            children: List.generate(
                              _weekdayLabels.length,
                              (index) => Expanded(
                                child: RoutineWeekdayCircle(
                                  label: _weekdayLabels[index],
                                  selected: _weekdays[index],
                                  onTap: () => _onWeekdayChanged(
                                    index,
                                    !_weekdays[index],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_repeatError != null) ...[
                            const SizedBox(height: 8),
                            AppFieldMessage(
                              message: _repeatError!,
                              isError: true,
                            ),
                          ],
                          const SizedBox(height: 16),
                          RoutineFormInfoLine(
                            text: widget.initialWeekday == null
                                ? '시간표에 바로 반영돼요'
                                : '달력에서 선택한 요일을 미리 골랐어요.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    RoutineFormSurface(
                      padding: EdgeInsets.zero,
                      child: InkWell(
                        onTap: () => setState(
                          () => _showMoreSettings = !_showMoreSettings,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.tune_rounded,
                                color: AppColors.orbitPrimary,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('더 설정하기',
                                        style: AppTextStyles.bodyStrong),
                                    SizedBox(height: 2),
                                    Text(
                                      '색상 · 알림',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _showMoreSettings
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_showMoreSettings) ...[
                      const SizedBox(height: 12),
                      RoutineFormSurface(
                        child: PastelColorPalette(
                          colors: routineFormPaletteColors,
                          selectedIndex: _paletteIndexForUi(),
                          onSelected: (index) => setState(() {
                            _selectedColorArgb = routineColorArgbNormalize(
                              routineFormPaletteColors[index].toARGB32(),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RoutineFormSurface(
                        child: PastelSwitchTile(
                          title: '알림 받기',
                          subtitle: '루틴 시작 시각에 알려드릴게요',
                          helper: '알림 권한은 설정에서 언제든 바꿀 수 있어요.',
                          value: _notificationEnabled,
                          onChanged: (value) => setState(
                            () => _notificationEnabled = value,
                          ),
                        ),
                      ),
                    ],
                    if (conflicts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      RoutineOverlapNotice(routine: conflicts.first),
                    ],
                    if (_isEdit) ...[
                      const SizedBox(height: 18),
                      TextButton.icon(
                        onPressed: isBusy ? null : _handleDelete,
                        icon: const Icon(Icons.delete_outline_rounded),
                        label: const Text('이 루틴 삭제'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _timeError = _timeRangeError();
    });
  }

  void _applySuggestion(String title) {
    setState(() {
      _nameController.text = title;
      _titleError = _titleValidationError(title);
    });
  }
}
