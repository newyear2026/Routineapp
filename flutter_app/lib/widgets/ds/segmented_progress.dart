import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 각 칸의 일부까지 채워 실제 비율을 유지하는 픽셀 진행 막대.
class SegmentedProgress extends StatelessWidget {
  const SegmentedProgress({
    super.key,
    required this.value,
    required this.semanticLabel,
    this.segmentCount = 10,
  });

  final double value;
  final String semanticLabel;
  final int segmentCount;

  @override
  Widget build(BuildContext context) {
    final progress = value.isFinite ? value.clamp(0.0, 1.0) : 0.0;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 18,
          child: Row(
            children: List.generate(
                segmentCount.clamp(1, 12),
                (index) {
                  final count = segmentCount.clamp(1, 12);
                  return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                            right: index == count - 1 ? 0 : 3),
                        decoration: BoxDecoration(
                          color: AppColors.orbitHalo,
                          border: Border.all(
                              color: AppColors.textPrimary, width: 1),
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FractionallySizedBox(
                            widthFactor:
                                (progress * count - index).clamp(0.0, 1.0),
                            heightFactor: 1,
                            child:
                                const ColoredBox(color: AppColors.orbitPrimary),
                          ),
                        ),
                      ),
                    );
                }),
          ),
        ),
      ),
    );
  }
}
