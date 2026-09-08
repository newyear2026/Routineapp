import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// PageView의 실제 현재 인덱스를 표시한다. 이동 동작은 기존 버튼이 담당한다.
class PixelSteps extends StatelessWidget {
  const PixelSteps({super.key, required this.total, required this.current})
      : assert(total > 0),
        assert(current >= 0 && current < total);

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) => Semantics(
        label: MaterialLocalizations.of(context)
            .tabLabel(tabIndex: current + 1, tabCount: total),
        child: ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                total,
                (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: index == current ? 28 : 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: index <= current
                            ? AppColors.orbitPrimary
                            : Colors.white,
                        border:
                            Border.all(color: AppColors.textPrimary, width: 2),
                      ),
                    )),
          ),
        ),
      );
}
