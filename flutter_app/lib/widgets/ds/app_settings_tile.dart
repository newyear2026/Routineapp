import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_status_badge.dart';

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
          Row(
            children: [
              _LeadingIcon(icon: icon, accent: accent, enabled: enabled),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              if (statusLabel != null) ...[
                AppStatusBadge(label: statusLabel!, tone: statusTone),
                const SizedBox(width: 8),
              ],
              // 값 표시(예: 현재 언어)는 언어마다 길이가 크게 달라진다.
              // 고정 폭으로 두면 'Según el dispositivo'에서 줄이 넘친다.
              if (trailing != null) Flexible(child: trailing!),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: 6),
            Padding(
              // 아이콘(42) + 간격(12)만큼 들여써 라벨과 왼쪽을 맞춘다.
              padding: const EdgeInsets.only(left: 54),
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
        borderRadius: BorderRadius.circular(18),
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
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: enabled ? accent : AppColors.textMuted,
        size: 21,
      ),
    );
  }
}
