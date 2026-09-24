import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_status_badge.dart';
import 'pixel_icon.dart';

/// 설정 행 — `아이콘 · 라벨(+배지) · 컨트롤` 한 줄, 설명은 그 아래 전체 폭.
///
/// 설명을 컨트롤과 같은 줄에 두면 스위치 옆에서 좁게 접혀 읽기 어려워진다.
class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    this.accent = AppColors.orbitPrimary,
    this.description,
    this.onTap,
    this.trailing,
    this.statusLabel,
    this.statusTone = AppStatusBadgeTone.neutral,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final String? description;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? statusLabel;
  final AppStatusBadgeTone statusTone;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final description = this.description;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 컨트롤은 flex를 나눠 갖지 않고 제 폭만 쓴 뒤 오른쪽 끝에 선다.
          // Flexible로 두면 라벨(Expanded)과 남는 폭을 반씩 갈라 가져,
          // 화살표처럼 좁은 컨트롤이 글자 바로 옆 한가운데에 섰다.
          LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                _LeadingIcon(icon: icon, accent: accent, enabled: enabled),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.control.copyWith(
                      color:
                          enabled ? AppColors.textPrimary : AppColors.textMuted,
                    ),
                  ),
                ),
                if (statusLabel != null) ...[
                  AppStatusBadge(label: statusLabel!, tone: statusTone),
                  const SizedBox(width: 8),
                ],
                // 값 표시(예: 현재 언어)는 언어마다 길이가 크게 달라진다.
                // 폭을 아예 풀어 주면 'Según el dispositivo'가 줄을 넘기므로
                // 행의 절반까지만 내주고, 그 안에서 줄이거나 말줄임하게 한다.
                if (trailing != null)
                  ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: constraints.maxWidth / 2),
                    child: trailing!,
                  ),
              ],
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Padding(
              // 설명은 카드 폭을 그대로 쓴다. 라벨 밑으로 54 들여쓰면 한글이
              // 마지막 한 글자만 다음 줄로 떨어진다.
              padding: const EdgeInsets.only(right: 2),
              child: Text(
                description,
                style: AppTextStyles.caption.copyWith(height: 1.35),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: enabled ? 1 : 0.7, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.zero,
        splashColor: AppColors.orbitPrimary.withValues(alpha: 0.1),
        highlightColor: AppColors.textMuted.withValues(alpha: 0.06),
        child: content,
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({
    required this.icon,
    required this.accent,
    required this.enabled,
  });

  final IconData icon;
  final Color accent;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: enabled ? 0.12 : 0.07),
        borderRadius: BorderRadius.zero,
      ),
      child: AppIcon(
        icon,
        color: enabled ? accent : AppColors.textMuted,
        size: 21,
      ),
    );
  }
}
