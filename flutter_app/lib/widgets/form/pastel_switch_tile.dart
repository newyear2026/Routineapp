import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// 알림 등 토글 한 줄
class PastelSwitchTile extends StatelessWidget {
  const PastelSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    this.helper,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orbitSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.orbitBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.orbitPrimary.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.notifications_outlined,
                color: AppColors.orbitPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted.withValues(alpha: 0.95),
                    ),
                  ),
                ],
                if (helper != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    helper!,
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.textMuted.withValues(alpha: 0.82),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.orbitPrimary,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: AppColors.orbitSurfaceSoft,
          ),
        ],
      ),
    );
  }
}
