import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/routine_form_palette.dart';
import '../theme/home_theme.dart';
import '../widgets/ds/app_card.dart';
import '../widgets/form/pastel_color_palette.dart';
import '../widgets/form/pastel_gradient_button.dart';
import '../widgets/form/pastel_switch_tile.dart';
import '../widgets/form/pastel_text_field.dart';
import '../widgets/form/pastel_time_field.dart';
import '../widgets/form/pastel_weekday_selector.dart';
import '../widgets/home/home_decorative_background.dart';

/// 루틴 추가 — Figma 톤, 폼은 로컬 state만 (저장 API 없음)
class RoutineAddScreen extends StatefulWidget {
  const RoutineAddScreen({super.key});

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

  static const _weekdayLabels = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void initState() {
    super.initState();
    _weekdays = [true, true, true, true, true, false, false];
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

  @override
  Widget build(BuildContext context) {
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
                        _buildAppBar(context),
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
                                    selectedIndex: _colorIndex.clamp(
                                      0,
                                      routineFormPaletteColors.length - 1,
                                    ),
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
                                  onPressed: () {
                                    FocusScope.of(context).unfocus();
                                    // 저장 로직은 추후 연결 — 현재는 UI만
                                  },
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

  Widget _buildAppBar(BuildContext context) {
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
          const Expanded(
            child: Text(
              '루틴 추가',
              textAlign: TextAlign.center,
              style: TextStyle(
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
