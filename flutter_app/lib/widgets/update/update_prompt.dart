import 'package:flutter/material.dart';

import '../../application/update/app_updates_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_pixel_style.dart';
import '../../theme/app_text_styles.dart';
import '../ds/app_button.dart';
import '../ds/app_card.dart';
import '../ds/pixel_icon.dart';

enum _UpdateChoice { update, later }

/// 업데이트를 한 번 권하고, 답에 따라 움직인다.
///
/// 뒤로 버튼으로도 닫힐 수 있고 그것은 어느 쪽 답도 아니다 — 다시는 말하지
/// 않겠다는 약속 없이 이번 끼어들기만 끝낸다. 결정은 «나중에하기»뿐이고,
/// 기억되는 것도 그것뿐이다.
Future<void> showUpdatePrompt(
  BuildContext context, {
  required AppUpdates updates,
  String? currentVersion,
}) async {
  // 다이얼로그 뒤가 아니라 앞이다. 정책이 «끼어들기를 썼다»를 이미 알고 있어야,
  // 열려 있는 동안 다시 그려지는 것들이 두 번째 사본을 요구할 수 없는 상태를
  // 본다.
  updates.markPromptShown();
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);

  final choice = await showDialog<_UpdateChoice>(
    context: context,
    barrierColor: const Color(0x99221C42),
    builder: (context) => _UpdatePromptDialog(currentVersion: currentVersion),
  );
  updates.markPromptClosed();

  if (choice == _UpdateChoice.later) {
    await updates.dismiss();
    return;
  }
  if (choice != _UpdateChoice.update) return;
  if (await updates.openStore()) return;
  // 스토어도 없고, 브라우저도 없고, 목록도 없다. 그렇다고 말하는 것이 복구의
  // 전부다 — 여기서 앱이 사용자를 대신해 할 수 있는 일이 없다.
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(l10n.updateStoreFailed)));
}

class _UpdatePromptDialog extends StatelessWidget {
  const _UpdatePromptDialog({this.currentVersion});

  /// 플랫폼이 돌고 있는 빌드를 알려 주지 않으면 null이다. 그때는 줄표로
  /// 보여 주는 대신 행을 뺀다 — 버전을 이야기하는 다이얼로그 안에서 «—»로
  /// 읽히는 버전은 답하는 것보다 질문을 더 만든다.
  final String? currentVersion;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final version = currentVersion;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        decoration: appSurfaceDecoration(elevated: true),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIcon(
                    Icons.arrow_circle_up_rounded,
                    size: 24,
                    color: AppColors.orbitPrimary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      l10n.updateAvailableTitle,
                      style: AppTextStyles.titleSection,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(l10n.updateAvailableBody, style: AppTextStyles.helper),
              if (version != null) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: ShapeDecoration(
                      color: AppColors.orbitHalo,
                      shape: AppPixelStyle.shape(steps: 2),
                    ),
                    child: Text(
                      l10n.updateCurrentVersion(version),
                      style: AppTextStyles.captionTight.copyWith(
                        color: AppColors.orbitPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              AppButton(
                label: l10n.updateAction,
                icon: Icons.open_in_new_rounded,
                height: 50,
                onPressed: () =>
                    Navigator.of(context).pop(_UpdateChoice.update),
              ),
              const SizedBox(height: 8),
              AppButton(
                label: l10n.updateLater,
                variant: AppButtonVariant.secondary,
                height: 50,
                onPressed: () => Navigator.of(context).pop(_UpdateChoice.later),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
