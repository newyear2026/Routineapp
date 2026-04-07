import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'app_status_badge.dart';

class AppSettingsTile extends StatelessWidget {
  const AppSettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.accent,
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
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          _LeadingIcon(icon: icon, accent: accent, enabled: enabled),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 15,
                          color: enabled
                              ? AppColors.textPrimary
                              : AppColors.textMuted.withValues(alpha: 0.84),
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ),
                    if (statusLabel != null)
                      AppStatusBadge(label: statusLabel!, tone: statusTone),
                  ],
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    description!,
                    style: AppTextStyles.caption.copyWith(height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
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
        splashColor: AppColors.accentPink.withValues(alpha: 0.12),
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
        color: accent.withValues(alpha: enabled ? 0.28 : 0.16),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: accent.withValues(alpha: enabled ? 0.25 : 0.14),
        ),
      ),
      child: Icon(
        icon,
        color: accent.withValues(alpha: enabled ? 0.95 : 0.55),
        size: 21,
      ),
    );
  }
}
