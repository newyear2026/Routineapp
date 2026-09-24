import 'package:flutter/material.dart';

import '../../domain/models/routine_icon_id.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/ds/routine_mark.dart';

class RoutineIconPicker extends StatelessWidget {
  const RoutineIconPicker({
    super.key,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final RoutineIconId selected;
  final Color color;
  final ValueChanged<RoutineIconId> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context).routineAddIconSection,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final icon in RoutineIconId.pickerOrder)
              InkWell(
                key: Key('routine-icon-${icon.name}'),
                onTap: () => onSelected(icon),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: ShapeDecoration(
                    color: AppColors.orbitSurface,
                    shape: AppPixelStyle.shape(
                      color: icon == selected
                          ? AppColors.orbitPrimary
                          : AppColors.orbitBorder,
                      width: icon == selected ? 2 : 1,
                      step: AppPixelStyle.cornerStepSmall,
                    ),
                  ),
                  child: Center(
                    child: RoutineMark(icon: icon, color: color, size: 42),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
