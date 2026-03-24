import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

/// 월~일 토글 칩 (반복 요일)
class PastelWeekdaySelector extends StatelessWidget {
  const PastelWeekdaySelector({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  /// 보통 ['월','화','수','목','금','토','일']
  final List<String> labels;
  final List<bool> selected;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '반복 요일',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HomeTheme.textMuted,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(labels.length, (i) {
            final on = i < selected.length && selected[i];
            return FilterChip(
              label: Text(labels[i]),
              selected: on,
              onSelected: (v) => onChanged(i, v),
              showCheckmark: false,
              selectedColor: HomeTheme.accentPink.withValues(alpha: 0.35),
              backgroundColor: Colors.white.withValues(alpha: 0.55),
              side: BorderSide(
                color: on
                    ? HomeTheme.accentPink.withValues(alpha: 0.65)
                    : const Color(0xFFE8DDFA).withValues(alpha: 0.5),
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: on ? HomeTheme.textPrimary : HomeTheme.textMuted,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
            );
          }),
        ),
      ],
    );
  }
}
