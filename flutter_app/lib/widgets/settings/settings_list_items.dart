import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';
import '../ds/app_pixel_switch.dart';

class SettingsToggleTile extends StatelessWidget {
  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.accent = AppColors.orbitPrimary,
    this.enabled = true,
    this.description,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return AppSettingsTile(
      icon: icon,
      label: label,
      accent: accent,
      description: description,
      enabled: enabled,
      trailing: AppPixelSwitch(
        label: label,
        value: value,
        accent: accent,
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}

class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.label,
    this.accent = AppColors.orbitPrimary,
    this.onTap,
    this.statusLabel,
    this.statusTone = AppStatusBadgeTone.readySoon,
    this.description,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final String? statusLabel;
  final AppStatusBadgeTone statusTone;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return AppSettingsTile(
      icon: icon,
      label: label,
      accent: accent,
      description: description,
      onTap: onTap,
      enabled: enabled,
      statusLabel: statusLabel,
      statusTone: statusTone,
      // 비활성 항목에는 갈 곳이 없으므로 화살표 자리를 비운다.
      // '준비 중' 배지가 이미 상태를 말한다.
      trailing: enabled
          ? const AppIcon(
              Icons.chevron_right_rounded,
              color: AppColors.textMuted,
              size: 22,
            )
          : null,
    );
  }
}

class SettingsInfoTile extends StatelessWidget {
  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.accent = AppColors.orbitPrimary,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppSettingsTile(
      icon: icon,
      label: label,
      accent: accent,
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: const BoxDecoration(
          color: AppColors.orbitSurfaceSoft,
          borderRadius: BorderRadius.zero,
        ),
        child: Text(
          value,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
