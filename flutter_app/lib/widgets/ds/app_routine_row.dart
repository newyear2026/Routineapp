import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../domain/models/routine_icon_id.dart';
import 'app_card.dart';
import 'app_status_badge.dart';
import 'pixel_icon.dart';
import 'routine_mark.dart';

/// 루틴 한 줄 — **홈·루틴 목록·캘린더·진행이 함께 쓰는 하나의 구현**.
///
/// 규칙은 하나다: **픽셀 아이콘 → 이름 → 보조 정보 → 오른쪽 슬롯.**
class AppRoutineRow extends StatelessWidget {
  const AppRoutineRow({
    super.key,
    required this.color,
    required this.title,
    this.icon = RoutineIconId.coffee,
    this.subtitle,
    this.subtitleBadge,
    this.trailing,
    this.onTap,
  });

  /// 아이콘 배경·강조색
  final Color color;

  final RoutineIconId icon;

  final String title;

  /// 이름 아래 한 줄 (시간 범위 등). 없으면 이름만.
  final String? subtitle;

  /// 설명 옆에 붙는 작은 칩 — 반복 주기처럼 성격이 다른 곁들이 정보.
  ///
  /// 시간 문자열에 ' · '로 이어 붙이면 둘이 같은 무게로 읽혀, 목록을 훑을 때
  /// 주기가 눈에 들어오지 않는다.
  final String? subtitleBadge;

  /// 오른쪽 슬롯 — 상태 배지, 시각 등.
  ///
  /// [onTap]이 있는데 [trailing]을 주지 않으면 chevron이 자동으로 붙는다.
  /// 누를 수 있는 줄에는 그렇게 보이는 단서가 있어야 한다.
  final Widget? trailing;

  final VoidCallback? onTap;

  static const double _radius = 0;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing ??
        (onTap == null
            ? null
            : const AppIcon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
              ));

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: appSurfaceDecoration(
        radius: _radius,
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Row(
        children: [
          RoutineMark(icon: icon, color: color, size: 36),
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
                  // 시각이 먼저다. 배지를 flex 자식으로 두면 Row가 여유 폭을
                  // 비율로 미리 쪼개서, 배지 쪽에 빈자리가 남는데도 시각이
                  // 줄어든다. 배지에는 상한만 씌우고 나머지를 시각이 가져간다.
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption,
                        ),
                      ),
                      if (subtitleBadge != null) ...[
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 88),
                          child: AppStatusBadge(
                            label: subtitleBadge!,
                            tone: AppStatusBadgeTone.meta,
                            compact: true,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            // trailing(시각·상태 배지)이 길어져도 루틴 이름을 밀어내지 않는다.
            Flexible(
                child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: trailing)),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_radius),
        child: content,
      ),
    );
  }
}
