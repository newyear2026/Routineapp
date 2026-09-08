import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../ds/app_card.dart';

/// 설정 섹션 제목 — Calm Editorial 톤의 담백한 라벨.
class SettingsSectionTitle extends StatelessWidget {
  const SettingsSectionTitle({super.key, required this.title, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: appSurfaceDecoration(),
      child: Column(
        children: children.asMap().entries.expand((entry) {
          final isLast = entry.key == children.length - 1;
          return [
            entry.value,
            if (!isLast)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.orbitBorder,
                indent: 14,
                endIndent: 14,
              ),
          ];
        }).toList(),
      ),
    );
  }
}
