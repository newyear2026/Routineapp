import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

/// 알림 등 토글 한 줄
class PastelSwitchTile extends StatelessWidget {
  const PastelSwitchTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8DDFA).withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(
                colors: [
                  HomeTheme.accentPink.withValues(alpha: 0.25),
                  const Color(0xFFD4E4FF).withValues(alpha: 0.35),
                ],
              ),
            ),
            child: const Icon(Icons.notifications_outlined, color: HomeTheme.textPrimary, size: 22),
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
                    color: HomeTheme.textPrimary,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: HomeTheme.textMuted.withValues(alpha: 0.95),
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
            activeTrackColor: HomeTheme.accentPink.withValues(alpha: 0.85),
            inactiveThumbColor: HomeTheme.textMuted.withValues(alpha: 0.5),
            inactiveTrackColor: HomeTheme.textMuted.withValues(alpha: 0.2),
          ),
        ],
      ),
    );
  }
}
