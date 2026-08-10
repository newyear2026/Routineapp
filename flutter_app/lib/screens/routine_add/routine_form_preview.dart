import 'package:flutter/material.dart';

import '../../domain/models/routine.dart';
import '../../domain/utils/time_minutes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/orbit_ring_painter.dart';

/// 편집 중인 루틴이 하루 어디에 놓이는지 보여주는 미리보기.
///
/// 링은 홈 화면·홈 위젯과 **같은 [OrbitRingPainter]**를 쓴다. 예전에는 이
/// 화면만 자체 페인터를 들고 있어서, 같은 하루 24시간이 앱 안에서 세 가지
/// 모양으로 그려졌다.
///
/// '지금' 바늘은 끈다. 여기서 보여주는 것은 현재 시각이 아니라 **저장하면
/// 어떻게 되는지**이므로, 바늘이 있으면 무엇을 가리키는지 헷갈린다.
class RoutineFormPreview extends StatelessWidget {
  const RoutineFormPreview({super.key, required this.candidate});

  final Routine candidate;

  @override
  Widget build(BuildContext context) {
    final title = candidate.title.trim().isEmpty ? '새 루틴' : candidate.title;

    return Container(
      height: 230,
      decoration: BoxDecoration(
        color: AppColors.orbitSurface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.orbitBorder),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 16,
            left: 20,
            child: Text(
              '미리보기',
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 190,
            height: 190,
            child: CustomPaint(
              painter: OrbitRingPainter(
                segments: [
                  OrbitRingSegment(
                    id: candidate.id,
                    startMinutes: candidate.startMinutesFromMidnight,
                    endMinutes: candidate.endMinutesFromMidnight,
                    color: candidate.color,
                  ),
                ],
                nowMinutes: candidate.startMinutesFromMidnight,
                showNowPointer: false,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSection,
              ),
              const SizedBox(height: 5),
              Text(
                TimeMinutes.formatRange(
                  candidate.startMinutesFromMidnight,
                  candidate.endMinutesFromMidnight,
                ),
                style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
