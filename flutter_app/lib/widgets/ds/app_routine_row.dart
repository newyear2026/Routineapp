import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_card.dart';

/// 루틴 한 줄 — **홈·루틴 목록·캘린더·진행이 함께 쓰는 하나의 구현**.
///
/// 예전에는 네 화면이 각자 private 위젯을 들고 있었고, 서피스·라운드·글자
/// 크기·정보 순서가 제각각이었다. 캘린더만 루틴 색을 배경 틴트로 써서 같은
/// 루틴이 화면에 따라 다른 물건처럼 보였고, 홈만 시각을 이름 위에 올려
/// 읽는 순서가 뒤집혀 있었다.
///
/// 규칙은 하나다: **색 원 → 이름 → 보조 정보 → 오른쪽 슬롯.**
/// 루틴의 정체성은 색 원이 맡는다 (`Routine.iconEmoji` 주석 참고).
///
/// 도메인 모델 대신 값만 받는다. `ds/`가 도메인에 의존하지 않게 하려는 것이고,
/// 덕분에 화면마다 필요한 보조 문구를 자유롭게 만들어 넘길 수 있다.
class AppRoutineRow extends StatelessWidget {
  const AppRoutineRow({
    super.key,
    required this.color,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  /// 루틴 색 — 왼쪽 원
  final Color color;

  final String title;

  /// 이름 아래 한 줄 (시간 범위, 반복 요일 등). 없으면 이름만.
  final String? subtitle;

  /// 오른쪽 슬롯 — 상태 배지, 시각 등.
  ///
  /// [onTap]이 있는데 [trailing]을 주지 않으면 chevron이 자동으로 붙는다.
  /// 누를 수 있는 줄에는 그렇게 보이는 단서가 있어야 한다.
  final Widget? trailing;

  final VoidCallback? onTap;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing ??
        (onTap == null
            ? null
            : const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ));

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: appSurfaceDecoration(radius: _radius),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyStrong,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.caption,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            // trailing(시각·상태 배지)이 길어져도 루틴 이름을 밀어내지 않는다.
            Flexible(child: trailing),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: AppColors.orbitSurface,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: content,
      ),
    );
  }
}
