# 루틴 타이머 앱 - Flutter 설정 가이드

## 1. Flutter 프로젝트 생성

```bash
flutter create routine_timer
cd routine_timer
```

## 2. pubspec.yaml 설정

제공된 `pubspec.yaml` 파일의 내용을 복사하여 붙여넣으세요.

주요 dependencies:
- `flutter_animate` - 애니메이션
- `go_router` - 라우팅
- `provider` - 상태 관리
- `shared_preferences` - 로컬 저장소
- `flutter_local_notifications` - 알림

```bash
flutter pub get
```

## 3. 프로젝트 구조

```
routine_timer/
├── lib/
│   ├── main.dart                              # 앱 진입점
│   ├── screens/                               # 화면들
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── notification_permission_screen.dart
│   │   ├── initial_routine_setup_screen.dart
│   │   ├── home_screen.dart
│   │   ├── today_progress_screen.dart
│   │   └── settings_screen.dart
│   ├── widgets/                               # 재사용 위젯
│   │   └── routine_detail_sheet.dart
│   ├── models/                                # 데이터 모델
│   │   └── routine.dart
│   └── utils/                                 # 유틸리티
│       ├── colors.dart
│       └── constants.dart
├── pubspec.yaml
└── README.md
```

## 4. 실행 방법

### iOS 시뮬레이터
```bash
flutter run -d iPhone
```

### Android 에뮬레이터
```bash
flutter run -d emulator
```

### 실제 기기
```bash
# 연결된 기기 확인
flutter devices

# 특정 기기에서 실행
flutter run -d [device-id]
```

## 5. 빌드 방법

### Android APK
```bash
flutter build apk --release
```

### iOS (macOS에서만)
```bash
flutter build ios --release
```

## 6. 주요 화면 경로

- `/` - 스플래시 화면
- `/onboarding` - 온보딩 (3단계)
- `/notification-permission` - 알림 권한 요청
- `/routine-setup` - 초기 루틴 설정
- `/home` - 메인 홈 화면 (원형 시간표)
- `/progress` - 오늘 진행률 화면
- `/settings` - 설정 화면

## 7. 추가 설정

### iOS (Info.plist)
알림 권한을 위해 `ios/Runner/Info.plist`에 추가:

```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### Android (AndroidManifest.xml)
`android/app/src/main/AndroidManifest.xml`에 추가:

```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

## 8. 현재 완성된 화면

✅ 스플래시 화면 (애니메이션 포함)
✅ 온보딩 화면 (3페이지, PageView)
✅ 알림 권한 요청 화면

🔄 작업 중:
- 초기 루틴 설정 화면
- 메인 홈 화면
- 진행률 화면
- 설정 화면

## 9. React vs Flutter 주요 차이

| React | Flutter |
|-------|---------|
| JSX | Widget 트리 |
| CSS/Tailwind | BoxDecoration, TextStyle |
| useState | setState, Provider |
| motion/react | AnimationController |
| React Router | go_router |
| .tsx | .dart |

## 10. 다음 단계

1. 나머지 화면들 완성
2. 데이터 모델 작성
3. 상태 관리 구현 (Provider)
4. 로컬 저장소 연동
5. 알림 기능 구현
6. 테스트 및 디버깅

## 문제 해결

### 패키지 설치 오류
```bash
flutter clean
flutter pub get
```

### iOS 빌드 오류
```bash
cd ios
pod install
cd ..
```

### Hot Reload 안될 때
```bash
r (hot reload)
R (hot restart)
```

## 유용한 명령어

```bash
# Flutter 버전 확인
flutter --version

# 의존성 업데이트
flutter pub upgrade

# 코드 분석
flutter analyze

# 테스트 실행
flutter test
```
