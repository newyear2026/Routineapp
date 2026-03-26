import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

/// 탭 시 시간 선택 다이얼로그 (로컬 state와 연결)
class PastelTimeField extends StatelessWidget {
  const PastelTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay value;
  final ValueChanged<TimeOfDay> onChanged;

  String _format(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: HomeTheme.textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: value,
                builder: (ctx, child) {
                  return Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: HomeTheme.textPrimary,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: HomeTheme.textPrimary,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onChanged(picked);
            },
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: const Color(0xFFE8DDFA).withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: HomeTheme.textMuted.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _format(value),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: HomeTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.expand_more,
                    size: 20,
                    color: HomeTheme.textMuted.withValues(alpha: 0.7),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
