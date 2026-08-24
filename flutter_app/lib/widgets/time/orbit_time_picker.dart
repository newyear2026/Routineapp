import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/utils/time_minutes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';

/// 앱 전용 **24시간 원형 시각 선택기**.
///
/// Material 기본 선택기를 쓰지 않는 이유:
/// 24시간제 로케일에서 기본 선택기의 시 다이얼은 바깥 링(0–11)과 안쪽 링
/// (12–23) 두 겹으로 그려진다. 화면이 좁으면 두 링의 숫자가 서로 겹쳐 읽을
/// 수 없다. 게다가 24시간제 여부를 로케일이 정해서(스페인어는 항상 24시간)
/// 언어마다 다른 화면이 나온다 — 앱은 어디서나 24시간 표기인데도.
///
/// 여기서는 **시를 한 겹 24칸 링**으로 그린다. 겹칠 구조 자체가 없고,
/// 홈의 24시간 원형 시간표와 같은 언어를 쓴다.
///
/// 문구는 [MaterialLocalizations]에서 가져온다 — 취소·확인·'시'·'분'은
/// Flutter가 이미 모든 언어로 갖고 있어 따로 번역할 필요가 없다.
Future<TimeOfDay?> showOrbitTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    builder: (context) => _OrbitTimePickerDialog(initialTime: initialTime),
  );
}

/// 다이얼이 무엇을 고르는 중인지.
enum _DialMode { hour, minute }

class _OrbitTimePickerDialog extends StatefulWidget {
  const _OrbitTimePickerDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_OrbitTimePickerDialog> createState() =>
      _OrbitTimePickerDialogState();
}

class _OrbitTimePickerDialogState extends State<_OrbitTimePickerDialog> {
  late int _hour = widget.initialTime.hour;
  late int _minute = widget.initialTime.minute;
  _DialMode _mode = _DialMode.hour;

  String get _hourText => TimeMinutes.formatTwoDigits(_hour);
  String get _minuteText => TimeMinutes.formatTwoDigits(_minute);

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        decoration: appSurfaceDecoration(radius: 28, elevated: true),
        // 화면이 짧거나 시스템 글꼴이 크면 통째로 스크롤한다.
        // 다이얼을 줄이는 대신 스크롤하는 편이 항상 읽을 수 있다.
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                materialL10n.timePickerDialHelpText,
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 12),
              _Header(
                hourText: _hourText,
                minuteText: _minuteText,
                hourLabel: materialL10n.timePickerHourLabel,
                minuteLabel: materialL10n.timePickerMinuteLabel,
                mode: _mode,
                onModeChanged: (mode) => setState(() => _mode = mode),
              ),
              const SizedBox(height: 18),
              // 다이얼 크기는 남는 폭에서 정한다. 값을 못 박으면 좁은 화면과
              // 큰 글꼴이 겹쳤을 때 대화상자 밖으로 넘친다.
              LayoutBuilder(
                builder: (context, constraints) => Center(
                  child: _Dial(
                    size: math.min(
                      _Dial.maxSize,
                      math.max(_Dial.minSize, constraints.maxWidth),
                    ),
                    mode: _mode,
                    hour: _hour,
                    minute: _minute,
                    onChanged: (value) => setState(() {
                      if (_mode == _DialMode.hour) {
                        _hour = value;
                      } else {
                        _minute = value;
                      }
                    }),
                    // 시를 고르면 분으로 자연스럽게 넘어간다.
                    onSettled: () {
                      if (_mode == _DialMode.hour) {
                        setState(() => _mode = _DialMode.minute);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Row가 아니라 Wrap이다 — 'Cancelar'·'ACEPTAR'처럼 긴 문구가
              // 큰 글꼴과 겹치면 한 줄에 들어가지 않는다. 넘치는 대신 접힌다.
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(materialL10n.cancelButtonLabel),
                  ),
                  TextButton(
                    key: const Key('orbit-time-picker-confirm'),
                    onPressed: () => Navigator.of(context).pop(
                      TimeOfDay(hour: _hour, minute: _minute),
                    ),
                    child: Text(materialL10n.okButtonLabel),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `HH : mm` — 누르면 시/분 중 무엇을 고를지 바뀐다.
class _Header extends StatelessWidget {
  const _Header({
    required this.hourText,
    required this.minuteText,
    required this.hourLabel,
    required this.minuteLabel,
    required this.mode,
    required this.onModeChanged,
  });

  final String hourText;
  final String minuteText;
  final String hourLabel;
  final String minuteLabel;
  final _DialMode mode;
  final ValueChanged<_DialMode> onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _HeaderField(
            fieldKey: const Key('orbit-time-picker-hour'),
            value: hourText,
            label: hourLabel,
            selected: mode == _DialMode.hour,
            onTap: () => onModeChanged(_DialMode.hour),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 14),
          child: Text(
            ':',
            style: AppTextStyles.statHero.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ),
        Expanded(
          child: _HeaderField(
            fieldKey: const Key('orbit-time-picker-minute'),
            value: minuteText,
            label: minuteLabel,
            selected: mode == _DialMode.minute,
            onTap: () => onModeChanged(_DialMode.minute),
          ),
        ),
      ],
    );
  }
}

class _HeaderField extends StatelessWidget {
  const _HeaderField({
    required this.fieldKey,
    required this.value,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key fieldKey;
  final String value;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: selected
              ? AppColors.orbitPrimary.withValues(alpha: 0.12)
              : AppColors.orbitSurfaceSoft.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: fieldKey,
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Semantics(
              selected: selected,
              label: '$label $value',
              child: Container(
                height: 72,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: FittedBox(
                  child: Text(
                    value,
                    style: AppTextStyles.statHero.copyWith(
                      color: selected
                          ? AppColors.orbitPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}

/// 한 겹 링 다이얼.
///
/// 시는 24칸(0–23), 분은 60칸이되 라벨은 5분 간격만 그린다.
/// 라벨을 위젯으로 배치해 두면 테스트가 실제 위치를 재서 겹침을 잡을 수 있다.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.size,
    required this.mode,
    required this.hour,
    required this.minute,
    required this.onChanged,
    required this.onSettled,
  });

  final double size;
  final _DialMode mode;
  final int hour;
  final int minute;
  final ValueChanged<int> onChanged;
  final VoidCallback onSettled;

  static const double maxSize = 268;
  static const double minSize = 196;

  /// 라벨 원이 다이얼 테두리를 넘지 않는 반지름.
  double get _labelRadius => size / 2 - _DialLabel.knob / 2 - 4;

  int get _divisions => mode == _DialMode.hour ? 24 : 60;
  int get _value => mode == _DialMode.hour ? hour : minute;

  /// 12시 방향이 0, 시계 방향으로 증가.
  double _angleFor(int value) => value / _divisions * 2 * math.pi;

  Offset _offsetFor(int value, double radius) {
    final angle = _angleFor(value) - math.pi / 2;
    return Offset(math.cos(angle) * radius, math.sin(angle) * radius);
  }

  int _valueFromLocal(Offset local) {
    final center = Offset(size / 2, size / 2);
    final vector = local - center;
    if (vector.distance < 12) return _value;
    var angle = math.atan2(vector.dy, vector.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final raw = angle / (2 * math.pi) * _divisions;
    return raw.round() % _divisions;
  }

  @override
  Widget build(BuildContext context) {
    // 시는 24칸 전부, 분은 5분 간격만 라벨을 그린다.
    // 60칸에 전부 적으면 어차피 읽을 수 없다.
    final labelled = mode == _DialMode.hour
        ? List<int>.generate(24, (i) => i)
        : List<int>.generate(12, (i) => i * 5);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => onChanged(_valueFromLocal(details.localPosition)),
      onTapUp: (_) => onSettled(),
      onPanUpdate: (details) =>
          onChanged(_valueFromLocal(details.localPosition)),
      onPanEnd: (_) => onSettled(),
      child: SizedBox(
        key: const Key('orbit-time-picker-dial'),
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 바탕 원과 바늘.
            Positioned.fill(
              child: CustomPaint(
                painter: _DialPainter(
                  angle: _angleFor(_value),
                  handLength: _labelRadius,
                ),
              ),
            ),
            for (final value in labelled)
              _DialLabel(
                offset: _offsetFor(value, _labelRadius),
                text: TimeMinutes.formatTwoDigits(value),
                selected: value == _value,
              ),
            // 5분 간격이 아닌 분에도 눈금을 남겨 선택을 알 수 있게 한다.
            if (mode == _DialMode.minute && minute % 5 != 0)
              _DialLabel(
                offset: _offsetFor(minute, _labelRadius),
                text: TimeMinutes.formatTwoDigits(minute),
                selected: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _DialLabel extends StatelessWidget {
  const _DialLabel({
    required this.offset,
    required this.text,
    required this.selected,
  });

  final Offset offset;
  final String text;
  final bool selected;

  /// 선택 표시 원의 지름. 라벨 간격보다 작아야 서로 닿지 않는다.
  static const double knob = 34;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: knob,
        height: knob,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orbitPrimary : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          text,
          maxLines: 1,
          style: AppTextStyles.caption.copyWith(
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  const _DialPainter({required this.angle, required this.handLength});

  final double angle;
  final double handLength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(
      center,
      size.width / 2,
      Paint()..color = AppColors.orbitHalo.withValues(alpha: 0.28),
    );

    final end = center +
        Offset(
          math.cos(angle - math.pi / 2) * handLength,
          math.sin(angle - math.pi / 2) * handLength,
        );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = AppColors.orbitPrimary
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      center,
      4,
      Paint()..color = AppColors.orbitPrimary,
    );
  }

  @override
  bool shouldRepaint(_DialPainter oldDelegate) =>
      oldDelegate.angle != angle || oldDelegate.handLength != handLength;
}
