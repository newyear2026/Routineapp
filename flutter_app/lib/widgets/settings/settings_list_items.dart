import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/ds.dart';

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
      trailing: _SettingsToggleSwitch(
        value: value,
        accent: accent,
        enabled: enabled,
        onChanged: onChanged,
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
    this.description,
  });

  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback? onTap;
  final String? statusLabel;
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
      statusTone: AppStatusBadgeTone.readySoon,
      // 비활성 항목에는 갈 곳이 없으므로 화살표 자리를 비운다.
      // '준비 중' 배지가 이미 상태를 말한다.
      trailing: enabled
          ? const Icon(
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
        decoration: BoxDecoration(
          color: AppColors.orbitSurfaceSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SettingsToggleSwitch extends StatelessWidget {
  const _SettingsToggleSwitch({
    required this.value,
    required this.accent,
    required this.enabled,
    required this.onChanged,
  });

  final bool value;
  final Color accent;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: 52,
          height: 30,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: value
                ? accent.withValues(alpha: enabled ? 1 : 0.35)
                : AppColors.orbitSurfaceSoft,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: value ? Colors.transparent : AppColors.orbitBorder,
            ),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
