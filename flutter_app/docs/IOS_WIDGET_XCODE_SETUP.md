# iOS Medium 위젯 설정

`Runner.xcodeproj`에는 `RoutineWidgetExtension` 타깃이 등록돼 있고,
`Runner.app/PlugIns`에 자동으로 포함된다. SwiftUI 화면은
`ios/RoutineWidgetExtension/RoutineWidgetExtension.swift`에 있다.

## 빌드 설정

- Widget Kind: `RoutineMediumWidget`
- 확장 번들 ID: `com.dayround.app.RoutineWidgetExtension`
- 확장 최소 버전: iOS 15
- 앱과 확장의 App Group: `group.com.dayround.app`
- 확장 버전은 Flutter의 `FLUTTER_BUILD_NAME` /
  `FLUTTER_BUILD_NUMBER`를 따른다.

배포 시 Xcode의 Runner·RoutineWidgetExtension 타깃에 같은 개발 팀을
설정하고 두 App ID의 App Groups capability를 확인한다. 기기 서명은
개발 팀의 프로비저닝 프로파일이 필요하다.

## 로컬 확인

1. `flutter pub get` 후 `cd ios && pod install`.
2. Xcode에서 `Runner.xcworkspace`를 열어 Runner를 빌드한다.
3. 앱을 한 번 실행해 위젯 공유 데이터를 저장한다.
4. 홈 화면에서 위젯 추가 → 하루한바퀴 → Medium 선택.

Xcode 27은 iOS 14 배포 타깃을 지원하지 않으므로 이 버전에서 서명 없는
로컬 빌드를 확인할 때는 `IPHONEOS_DEPLOYMENT_TARGET=15.0`을
빌드 옵션으로 지정한다. 저장소의 Runner 최소 버전 14.0은 변경하지 않았다.

위젯이 비어 있으면 앱을 열어 동기화하고 Runner·확장의 App Group ID가
일치하는지 확인한다.
