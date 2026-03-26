import 'onboarding_state.dart';

/// 앱 시작 시 [GoRouter] `initialLocation` 이후 첫 화면 경로 결정.
abstract final class OnboardingRouteSelector {
  /// 온보딩 미완료면 해당 단계 경로, 완료면 `/home`.
  static String resolveStartPath(OnboardingState state) {
    if (state.hasCompletedOnboarding) return '/home';
    final step = state.resumeStep;
    switch (step) {
      case OnboardingStep.intro:
        return '/onboarding';
      case OnboardingStep.initialRoutineSetup:
        return '/routine-setup';
      case OnboardingStep.notificationSetup:
        return '/notification-permission';
      case null:
        return '/home';
    }
  }

  /// [OnboardingStep] → 경로 (설정에서 특정 단계로 보낼 때 등)
  static String pathForStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.intro:
        return '/onboarding';
      case OnboardingStep.initialRoutineSetup:
        return '/routine-setup';
      case OnboardingStep.notificationSetup:
        return '/notification-permission';
    }
  }
}
