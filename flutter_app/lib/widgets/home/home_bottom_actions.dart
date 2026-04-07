import 'package:flutter/material.dart';
import '../../theme/home_theme.dart';

class HomeBottomActions extends StatelessWidget {
  const HomeBottomActions({
    super.key,
    required this.completeLabel,
    this.onComplete,
    this.onLater,
    this.onSkip,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
    this.disabledReason,
  });

  final String completeLabel;
  final VoidCallback? onComplete;
  final VoidCallback? onLater;
  final VoidCallback? onSkip;

  /// false면 완료 버튼 비활성(시간대 밖 등)
  final bool primaryEnabled;

  /// false면 나중에/건너뛰기 비활성
  final bool secondaryEnabled;
  final String? disabledReason;

  void _noop() {}

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: primaryEnabled ? 1 : 0.48,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: primaryEnabled ? (onComplete ?? _noop) : null,
              borderRadius: BorderRadius.circular(28),
              child: Ink(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8FA8DC), Color(0xFF6B8BC9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5A7AB8).withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Colors.white, size: 26),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        completeLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.25,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: secondaryEnabled ? 1 : 0.52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _LaterButton(
                  onTap: secondaryEnabled ? (onLater ?? _noop) : null,
                ),
              ),
              const SizedBox(width: 8),
              _SkipLinkButton(
                onTap: secondaryEnabled ? (onSkip ?? _noop) : null,
              ),
            ],
          ),
        ),
        if ((!primaryEnabled || !secondaryEnabled) && disabledReason != null) ...[
          const SizedBox(height: 10),
          Text(
            disabledReason!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: HomeTheme.textMuted.withValues(alpha: 0.88),
            ),
          ),
        ],
      ],
    );
  }
}

class _LaterButton extends StatelessWidget {
  const _LaterButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.white.withValues(alpha: 0.62),
            border: Border.all(
              color: HomeTheme.textMuted.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schedule_rounded,
                color: HomeTheme.textMuted.withValues(alpha: 0.88),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '나중에',
                style: TextStyle(
                  color: HomeTheme.textMuted.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 가장 약한 액션 — 텍스트로 의미를 분명히
class _SkipLinkButton extends StatelessWidget {
  const _SkipLinkButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.skip_next_rounded,
                size: 17,
                color: HomeTheme.textMuted.withValues(alpha: 0.42),
              ),
              const SizedBox(width: 4),
              Text(
                '건너뛰기',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.15,
                  color: HomeTheme.textMuted.withValues(alpha: 0.56),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
