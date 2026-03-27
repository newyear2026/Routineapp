/// 온보딩 단계 — [intro] → [initialRoutineSetup] → [notificationSetup]
enum OnboardingStep {
  intro,
  initialRoutineSetup,
  notificationSetup,
}

/// SharedPreferences 등에 저장하는 온보딩 진행 상태.
///
/// [hasCompletedOnboarding]는 세 플래그가 모두 참일 때 참이다.
class OnboardingState {
  const OnboardingState({
    required this.hasSeenIntro,
    required this.hasCompletedInitialRoutineSetup,
    required this.hasHandledNotificationSetup,
  });

  final bool hasSeenIntro;
  final bool hasCompletedInitialRoutineSetup;
  final bool hasHandledNotificationSetup;

  bool get hasCompletedOnboarding =>
      hasSeenIntro &&
      hasCompletedInitialRoutineSetup &&
      hasHandledNotificationSetup;

  /// 미완료 시 이어서 시작할 단계 (완료된 경우 null)
  OnboardingStep? get resumeStep {
    if (hasCompletedOnboarding) return null;
    if (!hasSeenIntro) return OnboardingStep.intro;
    if (!hasCompletedInitialRoutineSetup) {
      return OnboardingStep.initialRoutineSetup;
    }
    if (!hasHandledNotificationSetup) {
      return OnboardingStep.notificationSetup;
    }
    return null;
  }

  static const initial = OnboardingState(
    hasSeenIntro: false,
    hasCompletedInitialRoutineSetup: false,
    hasHandledNotificationSetup: false,
  );

  OnboardingState copyWith({
    bool? hasSeenIntro,
    bool? hasCompletedInitialRoutineSetup,
    bool? hasHandledNotificationSetup,
  }) {
    return OnboardingState(
      hasSeenIntro: hasSeenIntro ?? this.hasSeenIntro,
      hasCompletedInitialRoutineSetup: hasCompletedInitialRoutineSetup ??
          this.hasCompletedInitialRoutineSetup,
      hasHandledNotificationSetup:
          hasHandledNotificationSetup ?? this.hasHandledNotificationSetup,
    );
  }
}
