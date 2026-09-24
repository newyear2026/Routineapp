import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_pixel_style.dart';
import '../../widgets/ds/routine_mark.dart';
import '../../widgets/ds/pixel_decoration.dart';
import '../../widgets/store/character_pack_scope.dart';

/// 편집 중인 루틴의 아이콘·이름·시간을 보여준다.
class RoutineFormPreview extends StatelessWidget {
  const RoutineFormPreview({super.key, required this.candidate});

  final Routine candidate;

  @override
  Widget build(BuildContext context) {
    final garden = CharacterPackScope.currentOf(context).id == 'poodle_garden';
    final l10n = AppLocalizations.of(context);
    final title = candidate.title.trim().isEmpty
        ? l10n.routineAddTitleNew
        : candidate.title;

    return Container(
      decoration: ShapeDecoration(
        color: AppColors.orbitSurface,
        shape: AppPixelStyle.shape(),
      ),
      child: Stack(
        children: [
          if (title.characters.length <= 14 &&
              MediaQuery.sizeOf(context).width >= 360 &&
              MediaQuery.textScalerOf(context).scale(1) <= 1.2) ...[
            if (garden) ...[
              const Positioned(
                right: 16,
                bottom: 17,
                child: GardenLeaf(
                  key: Key('routine-add-preview-garden-leaf'),
                  size: 25,
                  mirror: true,
                ),
              ),
              const Positioned(
                right: 47,
                bottom: 2,
                child: PixelDecoration(
                  key: Key('routine-add-preview-garden-daisy'),
                  asset: 'garden-daisy',
                  size: 27,
                ),
              ),
            ] else
              Positioned(
                right: 10,
                bottom: 8,
                child: IgnorePointer(
                  child: Image.asset(
                    'assets/decorations/settings-card-cloud.png',
                    key: const Key('routine-add-preview-cloud'),
                    width: 100,
                    height: 50,
                    filterQuality: FilterQuality.none,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              RoutineMark(
                icon: candidate.iconId,
                color: candidate.color,
                size: 56,
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSection),
                  const SizedBox(height: 4),
                  Text(
                      TimeMinutes.formatRange(
                          candidate.startMinutesFromMidnight,
                          candidate.endMinutesFromMidnight),
                      style: AppTextStyles.body
                          .copyWith(color: AppColors.textMuted)),
                ],
              )),
            ]),
          ),
        ],
      ),
    );
  }
}
