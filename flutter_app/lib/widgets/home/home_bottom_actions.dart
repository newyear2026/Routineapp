import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

class HomeBottomActions extends StatelessWidget {
  const HomeBottomActions({
    super.key,
    required this.completeLabel,
    this.onComplete,
    this.onLater,
    this.onSkip,
  });

  final String completeLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onLater;
  final VoidCallback? onSkip;

  void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onComplete ?? _noop,
            borderRadius: BorderRadius.circular(28),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4E4FF), Color(0xFFC5D5F0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4E4FF).withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: HomeTheme.actionBlue, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    completeLabel,
                    style: const TextStyle(
                      color: HomeTheme.actionBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SecondaryButton(
                label: '나중에',
                icon: Icons.access_time,
                gradient: const [Color(0xFFFFE9D4), Color(0xFFFFDDC5)],
                iconColor: HomeTheme.actionOrange,
                onTap: onLater ?? _noop,
              ),
            ),
            const SizedBox(width: 8),
            _SecondaryButton(
              label: '',
              icon: Icons.skip_next,
              gradient: const [Color(0xFFFFE4E9), Color(0xFFFFD4E0)],
              iconColor: HomeTheme.actionRose,
              onTap: onSkip ?? _noop,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.iconColor,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final IconData icon;
  final List<Color> gradient;
  final Color iconColor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 48,
          padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: gradient),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              if (label.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: iconColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
