import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../application/routine_app_controller.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'ds/ds.dart';

/// 첫 로드가 실패했을 때 대신 보여 주는 복구 화면.
///
/// 돌아가는 동그라미만 띄우면 사용자는 기다리면 되는 줄 안다. 세 가지를
/// 말해야 한다 — 실패했다는 것, 저장된 루틴은 지우지 않았다는 것,
/// 다시 시도할 수 있다는 것.
///
/// 화면(Scaffold·AppScreenShell)은 호출하는 쪽이 감싼다. 이 위젯은 가운데
/// 들어갈 내용만 그린다.
class RoutineLoadFailureView extends StatefulWidget {
  const RoutineLoadFailureView({super.key});

  @override
  State<RoutineLoadFailureView> createState() => _RoutineLoadFailureViewState();
}

class _RoutineLoadFailureViewState extends State<RoutineLoadFailureView> {
  bool _retrying = false;

  Future<void> _retry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    // load 는 실패해도 던지지 않는다. 성공하면 컨트롤러가 알림을 보내
    // 화면이 통째로 바뀌므로, 여기서 결과를 따로 볼 일이 없다.
    await context.read<RoutineAppController>().load();
    if (!mounted) return;
    setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppIcon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.loadFailureTitle,
              style: AppTextStyles.titleSection,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.loadFailureBody,
              style: AppTextStyles.helper,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            AppButton(
              key: const Key('load-failure-retry'),
              label: l10n.commonRetry,
              icon: Icons.refresh_rounded,
              expand: false,
              isLoading: _retrying,
              onPressed: _retry,
            ),
          ],
        ),
      ),
    );
  }
}
