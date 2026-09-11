import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../ds/pixel_icon.dart';

/// 가로 스크롤 색상 선택 (픽셀 스와치)
class PastelColorPalette extends StatelessWidget {
  const PastelColorPalette({
    super.key,
    required this.colors,
    required this.selectedIndex,
    required this.onSelected,
    this.helperText,
    this.title,
  });

  final List<Color> colors;

  /// 팔레트에 없는 색이면 null → 선택 링 없음
  final int? selectedIndex;
  final ValueChanged<int> onSelected;
  final String? helperText;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title ?? AppLocalizations.of(context).commonColor,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: colors.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = colors[i];
              final sel = selectedIndex != null && i == selectedIndex;
              final checkColor = c.computeLuminance() > 0.48
                  ? AppColors.textPrimary
                  : Colors.white;
              return GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: c,
                    border: Border.all(
                      color: sel
                          ? AppColors.textPrimary
                          : Colors.white.withValues(alpha: 0.6),
                      width: sel ? 3 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33241F31),
                        blurRadius: 0,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  child: sel
                      ? AppIcon(Icons.check, size: 18, color: checkColor)
                      : null,
                ),
              );
            },
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 10),
          Text(
            helperText!,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AppColors.textMuted.withValues(alpha: 0.86),
            ),
          ),
        ],
      ],
    );
  }
}
