import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../ds/pixel_icon.dart';

/// 미룬 다이얼로그보다 오래 남는 조용한 한 줄.
///
/// 두 번째 다이얼로그도 아니고 스낵바도 아닌 것은 일부러다. 사용자가 무시하고
/// 싶은 동안에는 계속 무시할 수 있어야 하고, 마음이 바뀌었을 때는 아직 거기
/// 있어야 한다. 그래서 흐르지 않고 머무는 한 줄이다.
///
/// 색은 [AppColors.orbitHalo] 계열이다. 이것은 경고가 아니라 소식이므로
/// 코랄([AppColors.orbitSecondary])이나 경고 톤을 쓰면 무언가 잘못된 것처럼
/// 읽힌다.
class UpdateBanner extends StatelessWidget {
  const UpdateBanner({
    super.key,
    required this.onUpdate,
    required this.onDismiss,
  });

  final VoidCallback onUpdate;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: ShapeDecoration(
        color: AppColors.orbitHalo,
        shape: AppPixelStyle.shape(),
        shadows: const [
          BoxShadow(
            color: AppPixelStyle.shadow,
            offset: AppPixelStyle.cardOffset,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(11, 7, 5, 7),
      child: Row(
        children: [
          const AppIcon(
            Icons.arrow_circle_up_rounded,
            size: 20,
            color: AppColors.orbitPrimary,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              l10n.updateBannerMessage,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _BannerAction(label: l10n.updateAction, onPressed: onUpdate),
          IconButton(
            onPressed: onDismiss,
            icon: const AppIcon(Icons.close_rounded, size: 18),
            color: AppColors.textMuted,
            tooltip: l10n.updateBannerDismiss,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

/// 배너 안에 드는 작은 버튼.
///
/// [AppButton]을 쓰지 않는 이유는 그쪽의 기본 높이가 56이고, 한 줄 배너 안에서는
/// 배너 자신보다 키가 커지기 때문이다. 면·테두리·글자는 같은 토큰을 쓴다.
class _BannerAction extends StatelessWidget {
  const _BannerAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppPixelStyle.radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: ShapeDecoration(
            color: AppColors.orbitPrimary,
            shape: AppPixelStyle.shape(steps: 2),
          ),
          child: Text(
            label,
            style: AppTextStyles.captionTight.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
