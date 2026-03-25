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
import '../widgets/ds/app_card.dart';
import '../widgets/form/pastel_color_palette.dart';
import '../widgets/form/pastel_gradient_button.dart';
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

  int _colorIndex = 3;
  bool _notificationEnabled = true;

  Routine? _editingBaseline;

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  bool get _isEdit => widget.editRoutineId != null;

  @override
  void initState() {
    super.initState();
    _weekdays = [true, true, true, true, true, false, false];
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
    final colors = routineFormPaletteColors;
    final idx = colors.indexWhere((c) => c.toARGB32() == r.colorValue);
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
      _colorIndex = idx >= 0 ? idx : 3;
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
    });
  }

  int _colorIndexClamped() {
    final colors = routineFormPaletteColors;
    return _colorIndex.clamp(0, colors.length - 1);
  }

  Routine _routineFromForm() {
    final title = _nameController.text;
    const colors = routineFormPaletteColors;
    final idx = _colorIndexClamped();
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
        colorValue: colors[idx].toARGB32(),
        notificationEnabled: _notificationEnabled,
      );
    }

    return Routine.create(
      title: title,
      startTime: _startTime,
      endTime: _endTime,
      repeatWeekdays: repeat,
      colorValue: colors[idx].toARGB32(),
      notificationEnabled: _notificationEnabled,
    );
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

    final error = RoutineFormValidator.validateTitle(title) ??
        RoutineFormValidator.validateTimeRange(startMin, endMin) ??
        RoutineFormValidator.validateRepeatDays(repeat);
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
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

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: HomeTheme.pageGradient),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: HomeTheme.mobileWidth),
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
                        _buildAppBar(context, title),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      PastelTextField(
                                        label: '루틴 이름',
                                        hint: '예: 아침 스트레칭',
                                        controller: _nameController,
                                        textInputAction: TextInputAction.next,
                                      ),
                                      const SizedBox(height: 20),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: PastelTimeField(
                                              label: '시작',
                                              value: _startTime,
                                              onChanged: (t) => setState(() => _startTime = t),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: PastelTimeField(
                                              label: '종료',
                                              value: _endTime,
                                              onChanged: (t) => setState(() => _endTime = t),
                                            ),
                                          ),
                                        ],
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
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelColorPalette(
                                    colors: routineFormPaletteColors,
                                    selectedIndex: _colorIndexClamped(),
                                    onSelected: (i) => setState(() => _colorIndex = i),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppCard(
                                  child: PastelSwitchTile(
                                    title: '알림 받기',
                                    subtitle: '설정한 시간에 알림을 보내드릴게요',
                                    value: _notificationEnabled,
                                    onChanged: (v) => setState(() => _notificationEnabled = v),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                PastelGradientButton(
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

  Widget _buildAppBar(BuildContext context, String titleText) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: HomeTheme.textPrimary,
            tooltip: '뒤로',
          ),
          Expanded(
            child: Text(
              titleText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: HomeTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}
