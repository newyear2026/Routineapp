import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 온보딩 **미리보기** 경로.
///
/// `preview=1`이면 저장하지 않는다. `flow=1`이면 다음 미리보기 화면으로 이어진다.
/// 실제 첫 실행 다시 진행은 이 경로를 쓰지 않는다.
abstract final class OnboardingPreviewNav {
  static const hubPath = '/onboarding-preview';
  static const splashPath = '/splash-preview';
  static const queryPreview = 'preview';
  static const queryFlow = 'flow';

  static const splash = splashPath;
  static const splashFlow = '$splashPath?$queryFlow=1';
  static const intro = '/onboarding?$queryPreview=1';
  static const introFlow = '/onboarding?$queryPreview=1&$queryFlow=1';
  static const routine = '/routine-setup?$queryPreview=1';
  static const routineFlow = '/routine-setup?$queryPreview=1&$queryFlow=1';
  static const notification = '/notification-permission?$queryPreview=1';
  static const notificationFlow =
      '/notification-permission?$queryPreview=1&$queryFlow=1';

  static bool isPreview(GoRouterState state) =>
      state.uri.queryParameters[queryPreview] == '1';

  static bool isFlow(GoRouterState state) =>
      state.uri.queryParameters[queryFlow] == '1';

  /// 미리보기 한 화면을 마쳤을 때.
  ///
  /// [flow]이고 [nextPath]가 있으면 다음 화면으로 쌓는다.
  /// [flow]의 마지막 화면은 허브로 돌아간다. 저장은 호출자가 하지 않는다.
  static void finish(
    BuildContext context, {
    required bool flow,
    String? nextPath,
  }) {
    if (flow && nextPath != null) {
      context.push(nextPath);
      return;
    }
    if (flow) {
      context.go(hubPath);
      return;
    }
    context.pop();
  }

  static void leaveHub(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/settings');
  }
}
