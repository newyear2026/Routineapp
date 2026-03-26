# 온보딩 플로우

## 1. 상태 타입

- `lib/domain/onboarding/onboarding_state.dart` — `OnboardingState`, `OnboardingStep`
- 저장 키: `OnboardingLocalStorage` (`SharedPreferences`)

## 2. 진입 판단

- `lib/domain/onboarding/onboarding_route_selector.dart` — `OnboardingRouteSelector.resolveStartPath(OnboardingState)`
- 완료 시 `/home`, 미완료 시 마지막 미완료 단계 경로 (`/onboarding` → `/routine-setup` → `/notification-permission`)

## 3. 시작 라우팅

- `SplashScreen`에서 `OnboardingLocalStorage.load()` 후 `resolveStartPath`로 `context.go(...)`

## 4. 설정 «온보딩 다시 보기»

- `OnboardingLocalStorage.resetForReplay()` 후 `context.go('/onboarding')`
- `SettingsScreen` 개인화 섹션

## 단계 순서

1. **intro** — `OnboardingScreen` 끝·Skip 시 `markIntroSeen()` → 초기 루틴 설정  
2. **initialRoutineSetup** — 완료·「나중에 설정할게요」 시 `markInitialRoutineSetupCompleted()` → 알림  
3. **notificationSetup** — 허용·건너뛰기 시 `markNotificationSetupHandled()` → Home  

알림·초기 루틴은 **허용/완료와 명시적 건너뛰기 모두** 해당 단계 완료로 처리한다.
