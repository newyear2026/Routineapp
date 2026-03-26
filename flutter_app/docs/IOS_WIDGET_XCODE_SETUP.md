# iOS — WidgetKit 확장 추가 (Routine Medium)

Flutter는 `home_widget` + App Group으로 JSON을 저장한다. **시스템 위젯 UI**는 `ios/RoutineWidgetExtension/`의 Swift 소스로 구현한다.

## 전제

- Xcode 15+ 권장  
- 번들 ID 예: `com.example.routineTimer` (Runner와 동일 계열)  
- App Group: `group.com.example.routineTimer` (코드·Runner.entitlements와 동일)

## 1) App Group (Runner)

1. Xcode에서 `ios/Runner.xcworkspace` 연다.  
2. **Runner** 타깃 → **Signing & Capabilities** → **+ Capability** → **App Groups**.  
3. `group.com.example.routineTimer` 추가 (이미 `Runner/Runner.entitlements`에 있으면 확인만).

## 2) Widget Extension 타깃 생성

1. **File → New → Target…** → **Widget Extension**.  
2. Product Name: `RoutineWidgetExtension`  
3. **Include Live Activity** 끔.  
4. Finish 후 활성화 스킴에서 **RoutineWidgetExtension** 빌드 확인.

## 3) 기본 생성 파일 교체

Xcode가 만든 기본 `*Widget.swift` / `*Bundle.swift`는 제거하거나 타깃에서 제외하고,  
프로젝트에 이미 포함된 다음 파일을 **RoutineWidgetExtension 타깃에만** 넣는다:

- `ios/RoutineWidgetExtension/RoutineWidgetExtension.swift` (단일 `@main` WidgetBundle + Medium 위젯)
- `RoutineWidgetExtension.entitlements`에 동일 App Group 추가 (저장소에 샘플 있음).

## 4) 위젯 타깃 설정

- **Deployment Target**: iOS 14 이상  
- **Signing**: Team 선택  
- **Build Settings → Code Signing Entitlements**: `RoutineWidgetExtension/RoutineWidgetExtension.entitlements`  
- **General → Frameworks**: SwiftUI, WidgetKit (기본 포함)

## 5) Widget Kind

- Swift의 `kWidgetKind` / `RoutineMediumWidget`의 `kind`는 **`RoutineMediumWidget`** 이어야 한다.  
- Flutter `HomeWidget.updateWidget(iOSName: 'RoutineMediumWidget')`와 일치.

## 6) 빌드·실행

1. Runner로 앱 설치 후 한 번 실행 → 홈 데이터가 위젯 저장소에 기록됨.  
2. 홈 화면 길게 누르기 → 위젯 추가 → 앱 이름 → **Medium** 크기 선택.

## 문제 해결

- 위젯이 비어 있음: App Group ID가 Runner·Extension·Dart `HomeWidgetSyncService.appGroupId` 모두 동일한지 확인.  
- 타임라인 갱신 안 됨: 앱에서 `HomeWidget.updateWidget` 호출됨을 확인 (저장/로그 변경 후).
