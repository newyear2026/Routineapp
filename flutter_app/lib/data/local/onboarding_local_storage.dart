import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/onboarding/onboarding_state.dart';

/// 온보딩 플래그 — [SettingsRepository] 확장 전 MVP용 로컬 저장.
class OnboardingLocalStorage {
  OnboardingLocalStorage._();

  static const _kIntro = 'onboarding.has_seen_intro';
  static const _kRoutine = 'onboarding.has_completed_initial_routine_setup';
  static const _kNotification = 'onboarding.has_handled_notification_setup';

  static Future<OnboardingState> load() async {
    final p = await SharedPreferences.getInstance();
    return OnboardingState(
      hasSeenIntro: p.getBool(_kIntro) ?? false,
      hasCompletedInitialRoutineSetup: p.getBool(_kRoutine) ?? false,
      hasHandledNotificationSetup: p.getBool(_kNotification) ?? false,
    );
  }

  static Future<void> save(OnboardingState state) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kIntro, state.hasSeenIntro);
    await p.setBool(_kRoutine, state.hasCompletedInitialRoutineSetup);
    await p.setBool(_kNotification, state.hasHandledNotificationSetup);
  }

  static Future<void> markIntroSeen() async {
    final s = await load();
    await save(s.copyWith(hasSeenIntro: true));
  }

  static Future<void> markInitialRoutineSetupCompleted() async {
    final s = await load();
    await save(s.copyWith(hasCompletedInitialRoutineSetup: true));
  }

  static Future<void> markNotificationSetupHandled() async {
    final s = await load();
    await save(s.copyWith(hasHandledNotificationSetup: true));
  }

  /// 설정 «온보딩 다시 보기» — 처음 단계부터.
  static Future<void> resetForReplay() async {
    await save(OnboardingState.initial);
  }
}
